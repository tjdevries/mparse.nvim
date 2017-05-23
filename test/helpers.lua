local assert = require('luassert')
local util = require 'src.util'

local eq = function(exp, act)
  return assert.are.same(exp, act)
end

local neq = function(exp, act)
  return assert.are_not.same(exp, act)
end

local get_first_item = function(t)
  return t[1][1][1]
end

local get_item

get_item = function(t, param, key)
  if t[param] == key then
    return t
  end

  for k, v in ipairs(t) do
    -- print('checking k[param]: ', k, t[k][param])
    if t[k][param] == key then
      -- print('\treturning.... ', k, v, util.to_string(t))
      return t[k]
    end
  end

  local result = nil
  for k, v in ipairs(t) do
    if type(v) == 'table' then
      result = get_item(v, param, key)
      if (result) then return result end
    end
  end

  return nil
end

return {
  eq=eq,
  neq=neq,
  get_first_item=get_first_item,
  get_item=get_item,
}
