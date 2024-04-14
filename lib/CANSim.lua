
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

function convert_byte_array_to_ushort(value)
   datas = string.char(value[1], value[2])
   data = string.unpack('H', datas)
   return data
end

-- =====================

local id = 0
local id_str = ""
local instr_callbacks = {}


function new_message(id, payload)
   --print("received new message with id " .. id)
  
   address, port = parse_msg_id(id)
  
   if instr_callbacks[address] ~= nil then
        instr_callbacks[address](port, payload)
   end
end

function cansim_init(hw_id)
    id = hw_message_port_add(hw_id, new_message)
    id_str = hw_id
end

function cansim_is_connected()
    return hw_connected(id_str)
end


function cansim_send(canid, port, type, payload)
       --- print("AAA" .. canid)
    hw_message_port_send(id, create_msg_id(canid, port), type, payload)
end

function cansim_send_float(canid, port, value)
    cansim_send(canid, port, "BYTE[4]", convert_float_to_byte_array(value))
end

function cansim_send_cached_float(canid, port, value, tolerance)

    if not float_cache then float_cache = {} end
    
    local cached_value = float_cache[create_msg_id(canid, port)]
    if cached_value and math.abs(cached_value - value) < tolerance then return end
    --print ("CACHE MIS " .. canid .. " " .. port)
    cansim_send_float(canid, port, value)
    
    float_cache[create_msg_id(canid, port)] = value
end

function cansim_send_byte(canid, port, value)
    cansim_send(canid, port, "BYTE[1]", {value})
end

function cansim_send_cached_byte(canid, port, value)

    if not byte_cache then byte_cache = {} end
    
    local cached_value = byte_cache[create_msg_id(canid, port)]
    if cached_value and cached_value == value then return end
    --print ("CACHE MIS")
    cansim_send_byte(canid, port, value)
    
    byte_cache[create_msg_id(canid, port)] = value
end

function cansim_register_instrument(canid, callback)
    instr_callbacks[canid] = callback
end