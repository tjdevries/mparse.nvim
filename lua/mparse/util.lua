local table_print
function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        if value ~= {} then
          table.insert(sb, "{\n");
          table.insert(sb, table_print (value, indent + 2, done))
          table.insert(sb, string.rep (" ", indent)) -- indent it
          table.insert(sb, "}\n");
        end
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\",\n", tostring(value)))
      else
        table.insert(sb, string.format(
        "%s = \"%s\",\n", tostring (key), tostring(value)))
      end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

local to_string = function(tbl)
  -- Use penlight if we've got it
  local ok = pcall("require('pl.pretty').write")

  if ok then
    return require('pl.pretty').write(tbl)
  end

  return (function(item)
    if  "nil"       == type( item ) then
      return tostring(nil)
    elseif  "table" == type( item ) then
      return table_print(item)
    elseif  "string" == type( item ) then
      return tbl
    else
      return tostring(tbl)
    end
  end)(tbl)
end

local t_concat = function(t1, t2)
  local t3 = {unpack(t1)}

  for I = 1,#t2 do
    t3[#t1 + I] = t2[I]
  end

  return t3
end

local contains = function(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

return {
  contains  = contains,
  t_concat  = t_concat,
  to_string = to_string,
}
