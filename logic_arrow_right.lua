cansim_init("ARDUINO_NANO_P")

-- transponder

cansim_register_instrument(31, function(port, payload)
  if (port == 1) then
    local squawk = convert_byte_array_to_ushort(payload)
    xpl_dataref_write("sim/cockpit2/radios/actuators/transponder_code", "int", squawk)
  end
  
  if (port == 0) then 
    xpl_dataref_write("sim/cockpit2/radios/actuators/transponder_mode", "int", payload - 1)
  end
  
  if (port == 2) then
     xpl_command("sim/radios/transponder_ident")
  end
end)


xpl_dataref_subscribe(
    "sim/cockpit2/radios/indicators/transponder_brightness",
    "FLOAT",
    function(value)
       cansim_send_cached_byte(31, 2, value > 0.3 and 1 or 0)
    end)
    
xpl_dataref_subscribe(
    "sim/cockpit2/electrical/bus_volts", 
    "FLOAT[8]",
    function(value)
      -- print("AA " ..  math.floor(value[1]))
       cansim_send_cached_byte(31, 1, math.floor(value[1]))
    end)
        
-- fuel

cansim_register_instrument(30, function(port, payload)
  print("Something on 30! with " .. port .. "payload " .. payload)
  local xpl_selector = 0
  if payload == 1 then xpl_selector = 1 end
  if payload == 2 then xpl_selector = 3 end
  
  xpl_dataref_write("sim/cockpit2/fuel/fuel_tank_selector", "int", xpl_selector)
  
  local fs_selector = "FUEL_SELECTOR_OFF"
  if payload == 1 then fs_selector = "FUEL_SELECTOR_LEFT" end
  if payload == 2 then fs_selector = "FUEL_SELECTOR_RIGHT" end
  fs2020_event(fs_selector)
  
end)

-- buttons

cansim_register_instrument(24, function(port, payload)
  print("Something! with " .. port .. "payload " .. payload)
  if port == 7 then 
     xpl_dataref_write("sim/cockpit/electrical/battery_on", "INT", payload)
     fs2020_event("MASTER_BATTERY_SET", payload)
  end
  if port == 6 then 
     xpl_dataref_write("sim/cockpit/electrical/generator_on", "INT[8]", {payload})
     fs2020_event("ALTERNATOR_SET", payload)
  end
  if port == 5 then 
     xpl_dataref_write("simcoders/rep/engine/electrical_fuelpump/switch_on_0", "INT", payload)
     fs2020_event("FUELSYSTEM_PUMP_SET", payload)
  end -- fuel pump
  if port == 4 then 
     xpl_dataref_write("sim/cockpit/electrical/landing_lights_on", "INT", payload) 
     fs2020_event("LANDING_LIGHTS_SET", payload)  
  end -- landing
  if port == 2 then 
     xpl_dataref_write("sim/cockpit/electrical/beacon_lights_on", "INT", payload) 
     fs2020_event("BEACON_LIGHTS_SET", payload)
  end -- beacm
  if port == 1 then 
     xpl_dataref_write("sim/cockpit/electrical/strobe_lights_on", "INT", payload) 
     fs2020_event("STROBES_SET", payload)
  end -- collision
  if port == 0 then 
     xpl_dataref_write("sim/cockpit/switches/pitot_heat_on", "INT", payload) 
     fs2020_event("PITOT_HEAT_SET", payload)
  end -- pitot
end)



-- connection sanity

local connection_timer_id = 0

function connection_timer_callback(count, max)
    local simulator_connected = xpl_connected()
    local sim_connected = cansim_is_connected()

  
    if simulator_connected and sim_connected then
       
        print("Connection status: " .. tostring(simulator_connected) .. " " .. tostring(sim_connected))
        
        cansim_send_byte(30, 0, 0)
        cansim_send_byte(31, 0, 0)
        
        timer_stop(connection_timer_id)
    end
end

connection_timer_id = timer_start(0, 500, connection_timer_callback)



