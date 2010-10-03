for _, name in ipairs(arg) do
  print('REGISTER_LOADER("' .. name .. '", luaopen_' ..
        name:gsub('%.', '_') .. ');')
end
