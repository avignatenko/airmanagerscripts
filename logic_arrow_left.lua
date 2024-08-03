cansim_init("ARDUINO_NANO_O")
--cansim_init("ARDUINO_NANO_P")


function airspeed(ids, value)
    cansim_send_cached_float(ids, 0, value, 0.1)
end

function turn_coordinator_slip(ids, value_slip)
    cansim_send_cached_float(ids, 1, value_slip, 0.01)
end

function turn_coordinator_roll(ids, value_roll)
    cansim_send_cached_float(ids, 0, value_roll, 0.05)
end

function vertical_rate(ids, value)
    cansim_send_cached_float(ids, 0, value, 0.01)
end

function altimeter(ids, value)
    cansim_send_cached_float(ids, 0, value, 0.1)
end

function hsi(ids, value)
    cansim_send_cached_float(ids, 0, value, 0.1)
end

function hsi_bug(ids, value)
    cansim_send_cached_float(ids, 1, value, 0.01)
end

function rpm(ids, value)
    cansim_send_cached_float(ids, 0, value, 0.1)
end

function fuel_flow(ids, value)
    cansim_send_cached_float(ids, 1, value, 0.01)
end

function map(ids, value)
    cansim_send_cached_float(ids, 0, value, 0.01)
end


fs2020_variable_subscribe("SUCTION PRESSURE", "Inches of Mercury", function(value)
         cansim_send_cached_float(29, 0, value, 0.01)
    end
)

xpl_dataref_subscribe(
    "sim/cockpit2/gauges/indicators/suction_1_ratio",
    "FLOAT",
    function(value)
         cansim_send_cached_float(29, 0, value, 0.01)
    end
)

fs2020_variable_subscribe(
    "AIRSPEED INDICATED",
    "Knots",
    function(value)
        airspeed(16, value)
    end
)
 
xpl_dataref_subscribe(
    "simcoders/rep/cockpit2/gauges/indicators/airspeed_kts_pilot",
    "FLOAT",
    function(value)
        airspeed(16, value)
    end
)


fs2020_variable_subscribe(
    "TURN COORDINATOR BALL", 
    "Position", 
    function(value)
        turn_coordinator_slip(19, -value * 3)
    end
)

xpl_dataref_subscribe(
    "sim/cockpit2/gauges/indicators/slip_deg",
    "FLOAT",
    function(value)
        turn_coordinator_slip(19, -value * 3)
    end
)

fs2020_variable_subscribe(
    "TURN INDICATOR RATE", 
    "Radians", 
    function(value)
        turn_coordinator_roll(19, value * 180 / 3.14)
    end
)


xpl_dataref_subscribe(
    "sim/cockpit2/gauges/indicators/turn_rate_roll_deg_pilot",
    "FLOAT",
    function(value)
        turn_coordinator_roll(19, value)
    end
)

fs2020_variable_subscribe(
    "INDICATED ALTITUDE",
    "Feet",
    function(value)
        altimeter(17, -value) --fixme: update instrument to set positive values
    end
)


xpl_dataref_subscribe(
    "simcoders/rep/cockpit2/gauges/indicators/altitude_ft_pilot",
    "FLOAT",
    function(value)
        altimeter(17, -value) --fixme: update instrument to set positive values
    end
)

cansim_register_instrument(
    17,
    function(port, payload)
        data = convert_byte_array_to_float(payload)
        print(data)
        fs2020_event("KOHLSMAN_SET", data * 16 * 33.864, 0)
        xpl_dataref_write("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot", "FLOAT", data)
    end
)

fs2020_variable_subscribe(
    "VERTICAL SPEED", 
    "Feet per minute", function(value)
        vertical_rate(18, value / 100)
    end
)

xpl_dataref_subscribe(
    "simcoders/rep/cockpit2/gauges/indicators/vvi_fpm_pilot",
    "FLOAT",
    function(value)
        vertical_rate(18, value / 100)
    end
)

fs2020_variable_subscribe(
    "HEADING INDICATOR", 
    "degrees", 
    function(value)
        hsi(20, value)
    end
)

fs2020_variable_subscribe(
     "AUTOPILOT HEADING LOCK DIR", 
     "degrees",
     function(value)
        hsi_bug(20, value)
     end
)


xpl_dataref_subscribe(
    "sim/cockpit/gyros/psi_vac_ind_degm",
    "FLOAT",
    function(value)
        hsi(20, value)
    end
)


xpl_dataref_subscribe(
    "sim/cockpit/autopilot/heading_mag",
    "FLOAT",
    function(value)
        hsi_bug(20, value)
    end
)

            
cansim_register_instrument(
    20,
    function(port, payload)
        data = convert_byte_array_to_float(payload)
        if port == 1 then
            if data < 0 then
                xpl_command("sim/autopilot/heading_down")
                fs2020_event("HEADING_BUG_DEC")
            else
                xpl_command("sim/autopilot/heading_up")
                fs2020_event("HEADING_BUG_INC")
            end
        end
        
        if port == 0 then       
            if data < 0 then
                xpl_command("sim/instruments/DG_sync_down")
                fs2020_event("GYRO_DRIFT_DEC")
            else
                xpl_command("sim/instruments/DG_sync_up")
                fs2020_event("GYRO_DRIFT_INC")
            end
        end
        
        --print(data)
    end
)

xpl_dataref_subscribe(
    "simcoders/rep/cockpit2/gauges/indicators/engine_0_rpm",
    "FLOAT",
    function(value)
        rpm(21, value)
    end
)

fs2020_variable_subscribe("GENERAL ENG RPM:1", "Rpm", 
    function(value)
        rpm(21, value)
    end
)
        
xpl_dataref_subscribe(
    "simcoders/rep/indicators/fuel/fuel_flow_0",
    "FLOAT",
    function(value)
        fuel_flow(22, value * 1350)
    end
)

fs2020_variable_subscribe("ENG FUEL FLOW GPH:1", "Gallons per hour", 
    function(value)
        fuel_flow(22, value)
    end
)




xpl_dataref_subscribe(
    "sim/cockpit2/engine/indicators/MPR_in_hg",
    "FLOAT[2]",
    function(value)
        map(22, value[1])
    end
)

fs2020_variable_subscribe("ENG MANIFOLD PRESSURE:1", "inHg", 
    function(value)
        map(22, value)
    end
)

cansim_register_instrument(
    23,
    function(port, payload)
    
       -- print("Received something for 23: " .. port .. " " .. payload)
    
        -- ap roll    
        if port == 8 then
             data = convert_byte_array_to_float(payload)
             if data < 440 then
                 rollValue = (data - 440) / (0 + 440) * 35;
             else
                 rollValue = (data - 440) / (1024 - 440) * 35;
             end
             xpl_dataref_write("thranda/autopilot/rollKnob", "FLOAT", rollValue)  
             print ("Data1: " .. data)
        end
        
        -- ap left button
        if port == 6 then      
             xpl_dataref_write("thranda/autopilot/roll", "INT", payload)   
             print ("Data: " .. payload)
        end
        
        -- ap right button
        if port == 7 then
           xpl_dataref_write("thranda/autopilot/hdg", "INT", payload)   
            print ("Data: " .. payload)
        end
        
        -- nav switch
        if port == 9 then
           print ("Data: " .. payload)
        end
        
        -- nav selector
        if port == 10 then
           print ("Data: " .. payload)
        end
        
        if port == 4 then
            cmd = (payload == 1 and "down" or "up")
            xpl_command("sim/flight_controls/landing_gear_" .. cmd)
        end

        if port == 5 then
            
            local fs2020_events = { [0] = "MAGNETO1_OFF", [1] = "MAGNETO1_RIGHT", [2] = "MAGNETO1_LEFT", [3] = "MAGNETO1_BOTH", [4] = "MAGNETO1_START"}
            
            fs2020_event(fs2020_events[payload])
            xpl_dataref_write(
                "sim/cockpit2/engine/actuators/ignition_key",
                "INT[8]",
                {payload},
                0,
                payload == 4 and true or false
            )
            print("BBB" .. payload)
        end
    end
)

-- gear light
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

xpl_dataref_subscribe(
    "sim/aircraft/parts/acf_gear_deploy",
    "FLOAT[10]",
    function(geardata)
      
        val_nose = (geardata[1] > 0.99 and 1 or 0)
        val2_left = (geardata[2] > 0.99 and 1 or 0)
        val3_right = (geardata[3] > 0.99 and 1 or 0)
          
        update_gear_leds()
    end
)

xpl_dataref_subscribe(
    "sim/cockpit2/electrical/bus_volts",
    "FLOAT[8]",
    function(volts)
        electrical_working = (volts[1] > 5) and true or false
        update_gear_leds()
    end
)

-- fuel

cansim_register_instrument(30, function(port, payload)
  print("Something! with " .. port .. "payload " .. payload)
end)

-- indicators
xpl_dataref_subscribe("sim/cockpit2/electrical/generator_amps", "FLOAT[8]", function(value)
   cansim_send_cached_float(27, 0, value[1], 0.1)
end)

xpl_dataref_subscribe("simcoders/rep/engine/oil/temp_f_0", "FLOAT", function(value)
   cansim_send_cached_float(27, 1, value, 0.1)
end)

xpl_dataref_subscribe("simcoders/rep/engine/oil/press_psi_0", "FLOAT", function(value)
   cansim_send_cached_float(27, 2, value, 0.1)
end)

xpl_dataref_subscribe("sim/cockpit2/temperature/outside_air_temp_degc", "FLOAT", function(value)
   cansim_send_cached_float(27, 3, value, 0.1)
end)

xpl_dataref_subscribe("simcoders/rep/indicators/fuel/fuel_quantity_ratio_0", "FLOAT", function(ratio)
   --print(math.floor(ratio*255))
   cansim_send_cached_float(25, 2, ratio * 40, 0.1)
end)

xpl_dataref_subscribe("simcoders/rep/indicators/fuel/fuel_quantity_ratio_1", "FLOAT", function(ratio)
   cansim_send_cached_float(25, 0, ratio * 40, 0.1)
end)


xpl_dataref_subscribe("sim/cockpit2/engine/indicators/fuel_pressure_psi", "FLOAT[2]", function(pressure)
   cansim_send_cached_float(25, 1, pressure[1], 0.1)
end)


fs2020_variable_subscribe(
    "ATTITUDE INDICATOR BANK DEGREES", 
    "Degrees", 
    function(value)
      cansim_send_cached_float(28, 1, -value, 0.05)
end)

fs2020_variable_subscribe(
   "ATTITUDE INDICATOR PITCH DEGREES", 
   "Degrees", 
   function(value)
       cansim_send_cached_float(28, 0, -value, 0.05)
end)


xpl_dataref_subscribe("simcoders/rep/cockpit2/gauges/indicators/attitude_indicator_0_roll", "FLOAT", function(value)
   cansim_send_cached_float(28, 1, value, 0.05)
end)

xpl_dataref_subscribe("simcoders/rep/cockpit2/gauges/indicators/attitude_indicator_0_pitch", "FLOAT", function(value)
   cansim_send_cached_float(28, 0, value, 0.05)
end)


-- leds & buttons upper left panel
function electrics_on(volts)
  electrical_working = (volts[1] > 5) and true or false
  return electrical_working
end


xpl_dataref_subscribe(
    "sim/cockpit2/annunciators/gear_unsafe", "INT", 
    "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 0, electrics_on(volts) and value or 0)
    end)

xpl_dataref_subscribe(
    "sim/cockpit2/engine/actuators/starter_hit", "INT[8]", 
    "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 1, electrics_on(volts) and value[1] or 0)
    end)

xpl_dataref_subscribe(
    "sim/cockpit2/annunciators/low_vacuum", "INT", 
    "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 2, electrics_on(volts) and value or 0)
    end)

xpl_dataref_subscribe(
    "sim/cockpit2/annunciators/generator", "INT", 
    "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 3, electrics_on(volts) and value or 0)
    end)


xpl_dataref_subscribe(
    "sim/cockpit2/annunciators/oil_pressure", "INT", 
    "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 4, electrics_on(volts) and value or 0)
    end)


xpl_dataref_subscribe(
    "sim/cockpit2/annunciators/low_voltage", "INT", 
    "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
    function(value, volts)
        cansim_send_cached_byte(26, 6, electrics_on(volts) and value or 0)
    end)
 
xpl_dataref_subscribe(
    "sim/flightmodel/engine/ENGN_MPR", "FLOAT[8]", 
    "sim/cockpit2/electrical/bus_volts", "FLOAT[8]",
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
    fs2020_event("TOGGLE_PRIMER1")
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
--cansim_send_byte(2, 0, 0)
--cansim_send_byte(30, 0, 0)
