is_rep_prop = user_prop_add_boolean("Is REP?", false, "Is REP aircraft?")

local is_rep = user_prop_get(is_rep_prop)
print("REP settings: " .. tostring(is_rep))

cansim_init("ARDUINO_NANO_O")

xpl_dataref_subscribe("sim/cockpit2/gauges/indicators/suction_1_ratio", "FLOAT", function(value)
    cansim_send_cached_float(29, 0, value, 0.01)
end)

-- airspeed --

local kts_dataref_rep = "simcoders/rep/cockpit2/gauges/indicators/airspeed_kts_pilot"
local kts_dataref = "sim/cockpit2/gauges/indicators/airspeed_kts_pilot"

xpl_dataref_subscribe(is_rep and kts_dataref_rep or kts_dataref, "FLOAT", function(value)
    cansim_send_cached_float(16, 0, value, 0.1)
end)

-- turn & roll --

xpl_dataref_subscribe("sim/cockpit2/gauges/indicators/slip_deg", "FLOAT", function(value)
    cansim_send_cached_float(19, 1, -value * 3, 0.01)
end)

xpl_dataref_subscribe("sim/cockpit2/gauges/indicators/turn_rate_roll_deg_pilot", "FLOAT", function(value)
    cansim_send_cached_float(19, 0, value, 0.05)
end)

-- altitude --

local alt_dataref_rep = "simcoders/rep/cockpit2/gauges/indicators/altitude_ft_pilot"
local alt_dataref = "sim/cockpit2/gauges/indicators/altitude_ft_pilot"
xpl_dataref_subscribe(is_rep and alt_dataref_rep or alt_dataref, "FLOAT", function(value)
    cansim_send_cached_float(17, 0, -value, 0.1) -- fixme: update instrument to set positive values
end)

cansim_register_instrument(17, function(port, payload)
    data = convert_byte_array_to_float(payload)
    print(data)
    xpl_dataref_write("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot", "FLOAT", data)
end)

-- vertical speed --

local vvi_fpm_dataref_rep = "simcoders/rep/cockpit2/gauges/indicators/vvi_fpm_pilot"
local vvi_fpm_dataref = "sim/cockpit2/gauges/indicators/vvi_fpm_pilot"

xpl_dataref_subscribe(is_rep and vvi_fpm_dataref_rep or vvi_fpm_dataref, "FLOAT", function(value)
    cansim_send_cached_float(18, 0, value / 100, 0.01)
end)

-- vacuum -- 

xpl_dataref_subscribe("sim/cockpit/gyros/psi_vac_ind_degm", "FLOAT", function(value)
    cansim_send_cached_float(20, 0, value, 0.1)
end)

-- heading -- 

xpl_dataref_subscribe("sim/cockpit/autopilot/heading_mag", "FLOAT", function(value)
    cansim_send_cached_float(29, 1, value, 0.01)
end)

cansim_register_instrument(20, function(port, payload)
    data = convert_byte_array_to_float(payload)
    if port == 1 then
        if data < 0 then
            xpl_command("sim/autopilot/heading_down")
        else
            xpl_command("sim/autopilot/heading_up")
        end
    end

    if port == 0 then
        if data < 0 then
            xpl_command("sim/instruments/DG_sync_down")
        else
            xpl_command("sim/instruments/DG_sync_up")
        end
    end
end)

-- rpm --

xpl_dataref_subscribe(is_rep and "simcoders/rep/cockpit2/gauges/indicators/engine_0_rpm" or
                          "sim/cockpit2/engine/indicators/engine_speed_rpm", is_rep and "FLOAT" or "FLOAT[2]",
    function(value)
        print("rpm: " .. value[1])
        cansim_send_cached_float(21, 0, is_rep and value or value[1], 0.1)
    end)

-- fuel flow --

xpl_dataref_subscribe(is_rep and "simcoders/rep/indicators/fuel/fuel_flow_0" or
                          "sim/cockpit2/engine/indicators/fuel_flow_kg_sec", is_rep and "FLOAT" or "FLOAT[2]",
    function(value)
        cansim_send_cached_float(22, 1, is_rep and (value * 1350) or (value[1] * 951), 0.01)
    end)

-- MPR --

xpl_dataref_subscribe("sim/cockpit2/engine/indicators/MPR_in_hg", "FLOAT[2]", function(value)
    cansim_send_cached_float(22, 0, value[1], 0.01)
end)

-- lower panel: AP, ignition, gear

cansim_register_instrument(23, function(port, payload)
    -- print("Received something for 23: " .. port .. " " .. payload)

    -- ap roll
    if port == 8 then
        data = convert_byte_array_to_float(payload)
        if data < 440 then
            rollValue = (data - 440) / (0 + 440) * 35
        else
            rollValue = (data - 440) / (1024 - 440) * 35
        end
        xpl_dataref_write("thranda/autopilot/rollKnob", "FLOAT", rollValue)
        print("Data1: " .. data)
    end

    -- ap left button
    if port == 6 then
        xpl_dataref_write("thranda/autopilot/roll", "INT", payload)
        print("Data: " .. payload)
    end

    -- ap right button
    if port == 7 then
        xpl_dataref_write("thranda/autopilot/hdg", "INT", payload)
        print("Data: " .. payload)
    end

    -- nav switch
    if port == 9 then
        print("Data: " .. payload)
    end

    -- nav selector
    if port == 10 then
        print("Data: " .. payload)
    end

    if port == 4 then
        cmd = (payload == 1 and "down" or "up")
        xpl_command("sim/flight_controls/landing_gear_" .. cmd)
    end

    if port == 5 then
        xpl_dataref_write("sim/cockpit2/engine/actuators/ignition_key", "INT[8]", {payload}, 0,
            payload == 4 and true or false)
        print("BBB" .. payload)
    end
end)

-- gear light --

local electrical_working = 0
val_nose = 0
val2_left = 0
val3_right = 0

function update_gear_leds()
    if electrical_working then
        cansim_send_cached_byte(23, 2, val_nose)
        cansim_send_cached_byte(23, 0, val2_left)
        cansim_send_cached_byte(23, 1, val3_right)
    else
        cansim_send_cached_byte(23, 2, 0)
        cansim_send_cached_byte(23, 0, 0)
        cansim_send_cached_byte(23, 1, 0)
    end
end

xpl_dataref_subscribe("sim/aircraft/parts/acf_gear_deploy", "FLOAT[10]", function(geardata)
    val_nose = (geardata[1] > 0.99 and 1 or 0)
    val2_left = (geardata[2] > 0.99 and 1 or 0)
    val3_right = (geardata[3] > 0.99 and 1 or 0)

    update_gear_leds()
end)

xpl_dataref_subscribe("sim/cockpit2/electrical/bus_volts", "FLOAT[8]", function(volts)
    electrical_working = (volts[1] > 5) and true or false
    update_gear_leds()
end)

-- fuel

cansim_register_instrument(30, function(port, payload)
    print("Something! with " .. port .. "payload " .. payload)
end)

-- indicators

xpl_dataref_subscribe("sim/cockpit2/electrical/generator_amps", "FLOAT[8]", function(value)
    cansim_send_cached_float(27, 0, value[1], 0.1)
end)

xpl_dataref_subscribe(is_rep and "simcoders/rep/engine/oil/temp_f_0" or
                          "sim/cockpit2/engine/indicators/oil_temperature_deg_C", is_rep and "FLOAT" or "FLOAT[2]",
    function(value)
        cansim_send_cached_float(27, 1, is_rep and value or value[1], 0.1)
    end)

xpl_dataref_subscribe(is_rep and "simcoders/rep/engine/oil/press_psi_0" or
                          "sim/cockpit2/engine/indicators/oil_pressure_psi", is_rep and "FLOAT" or "FLOAT[2]",
    function(value)
        cansim_send_cached_float(27, 2, is_rep and value or value[1], 0.1)
    end)

xpl_dataref_subscribe("sim/cockpit2/temperature/outside_air_temp_degc", "FLOAT", function(value)
    cansim_send_cached_float(27, 3, value, 0.1)
end)

xpl_dataref_subscribe(is_rep and "simcoders/rep/indicators/fuel/fuel_quantity_ratio_0" or
                          "sim/cockpit2/fuel/fuel_quantity", is_rep and "FLOAT" or "FLOAT[2]", function(ratio)
    cansim_send_cached_float(25, 2, is_rep and (ratio * 40) or (ratio[1] * 0.33), 0.1)
end)

xpl_dataref_subscribe(is_rep and "simcoders/rep/indicators/fuel/fuel_quantity_ratio_1" or
                          "sim/cockpit2/fuel/fuel_quantity", is_rep and "FLOAT" or "FLOAT[2]", function(ratio)
    cansim_send_cached_float(25, 0, is_rep and (ratio * 40) or (ratio[2] * 0.33), 0.1)
end)

xpl_dataref_subscribe("sim/cockpit2/engine/indicators/fuel_pressure_psi", "FLOAT[2]", function(pressure)
    cansim_send_cached_float(25, 1, pressure[1], 0.1)
end)

-- attitude indicator

xpl_dataref_subscribe(is_rep and "simcoders/rep/cockpit2/gauges/indicators/attitude_indicator_0_roll" or
                          "sim/cockpit2/gauges/indicators/roll_vacuum_deg_pilot", "FLOAT", function(value)
    cansim_send_cached_float(28, 1, value, 0.05)
end)

xpl_dataref_subscribe(is_rep and "simcoders/rep/cockpit2/gauges/indicators/attitude_indicator_0_pitch" or
                          "sim/cockpit2/gauges/indicators/pitch_vacuum_deg_pilot", "FLOAT", function(value)
    cansim_send_cached_float(28, 0, value, 0.05)
end)

-- leds & buttons upper left panel
function electrics_on(volts)
    electrical_working = (volts[1] > 5) and true or false
    return electrical_working
end

xpl_dataref_subscribe("sim/cockpit2/annunciators/gear_unsafe", "INT", "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 0, electrics_on(volts) and value or 0)
    end)

xpl_dataref_subscribe("sim/cockpit2/engine/actuators/starter_hit", "INT[8]", "sim/cockpit2/electrical/bus_volts",
    "FLOAT[8]", function(value, volts)
        cansim_send_cached_byte(26, 1, electrics_on(volts) and value[1] or 0)
    end)

xpl_dataref_subscribe("sim/cockpit2/annunciators/low_vacuum", "INT", "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 2, electrics_on(volts) and value or 0)
    end)

xpl_dataref_subscribe("sim/cockpit2/annunciators/generator", "INT", "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 3, electrics_on(volts) and value or 0)
    end)

xpl_dataref_subscribe("sim/cockpit2/annunciators/oil_pressure", "INT", "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 4, electrics_on(volts) and value or 0)
    end)

xpl_dataref_subscribe("sim/cockpit2/annunciators/low_voltage", "INT", "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 6, electrics_on(volts) and value or 0)
    end)

xpl_dataref_subscribe("sim/flightmodel/engine/ENGN_MPR", "FLOAT[8]", "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 5, electrics_on(volts) and (value[1] >= 41 and 1 or 0) or 0)
    end)

cansim_register_instrument(26, function(port, payload)
    print("Something! with " .. port .. "payload " .. payload)
    if port == 0 then
        xpl_dataref_write("thranda/annunciators/AnnunTest", "FLOAT", payload)
    end

    if port == 1 then
        xpl_dataref_write("simcoders/rep/cockpit2/engine/actuators/primer_0", "INT", payload)
    end
end)

-- connection sanity

local connection_timer_id = 0

function connection_timer_callback(count, max)
    local simulator_connected = xpl_connected()
    local sim_connected = cansim_is_connected()

    if simulator_connected and sim_connected then
        print("Connection status: " .. tostring(simulator_connected) .. " " .. tostring(sim_connected))

        cansim_send(23, 4, "BYTE[1]", {0})
        cansim_send(23, 5, "BYTE[1]", {0})
        cansim_send(23, 6, "BYTE[1]", {0})
        cansim_send(23, 7, "BYTE[1]", {0})
        cansim_send(23, 8, "BYTE[1]", {0})
        cansim_send(23, 9, "BYTE[1]", {0})
        cansim_send(23, 10, "BYTE[1]", {0})
        timer_stop(connection_timer_id)
    end
end

connection_timer_id = timer_start(0, 500, connection_timer_callback)

-- statistics
-- cansim_send_byte(2, 0, 0)
-- cansim_send_byte(30, 0, 0)
