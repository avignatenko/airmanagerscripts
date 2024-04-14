

function create_msg_id(address, port)
    return address + port * (2 ^ 10)
end

function parse_msg_id(msg_id)
   address = msg_id % (2 ^ 10)
   port = msg_id // (2 ^ 10)
   
   return address, port
end

function convert_word_to_byte_array(value)
   return  {value % 256, math.floor(value / 256)}
end

function convert_float_to_byte_array(value)
   buffer = {} 
   value =  value + 0.0 
   -- pack the string, 
   b = string.pack('f', value) 
   -- then get the bytes.        
   for i = 1, 4, 1 do
        buffer[i] = string.byte(b, i);   
   end 
      
   return buffer;
end

function convert_byte_array_to_float(value)
   datas = string.char(value[1], value[2], value[3], value[4])
   data = string.unpack('f', datas)
   return data
end

-- This function will be called when a message is received from the Arduino.
function new_message(id, payload)
   --print("received new message with id " .. id)
  
   address, port = parse_msg_id(id)
  
   
   --print("addr=" .. address .. ", port= " .. port)
   --
   
   if address == 17 then 
     data = convert_byte_array_to_float(payload)
     --print(data)
     fsx_variable_write("KOHLSMAN SETTING HG", "inHg", data)
   end
end

id = hw_message_port_add("ARDUINO_NANO_P", new_message)



function airspeed(ids, value)  
   hw_message_port_send(id, create_msg_id(ids, 0), "BYTE[4]", convert_float_to_byte_array(value))
end

function turn_coordinator_slip(ids, value_slip)
   hw_message_port_send(id, create_msg_id(ids, 1), "BYTE[4]", convert_float_to_byte_array(value_slip))
end

function turn_coordinator_roll(ids, value_roll)
   hw_message_port_send(id, create_msg_id(ids, 0), "BYTE[4]", convert_float_to_byte_array(value_roll))
end

function vertical_rate(ids, value)
   hw_message_port_send(id, create_msg_id(ids, 0), "BYTE[4]", convert_float_to_byte_array(value))
end

function altimeter(ids, value)
   hw_message_port_send(id, create_msg_id(ids, 0), "BYTE[4]", convert_float_to_byte_array(value))
end

fsx_variable_subscribe("L:AirspeedNeedle", "mph", function(value) airspeed(16, value / 1.15077945)  end)
fsx_variable_subscribe("TURN COORDINATOR BALL", "Position", function(value) turn_coordinator_slip(19, value * 10) end)
fsx_variable_subscribe("TURN INDICATOR RATE", "Radians",  function(value) turn_coordinator_roll(19, value * 300) end)
fsx_variable_subscribe("INDICATED ALTITUDE", "Feet",  function(value) altimeter(17, value) end)
fsx_variable_subscribe("VERTICAL SPEED", "Feet per minute",  function(value) vertical_rate(18, value / 100) end)


