local nvim = vim.api

local cache = {}
cache.enabled = false
cache.values = {}

cache.clear_cache = function()
  cache.values = {}
end

cache.call_cache = function(func, arg)
  if cache.enabled then
    if cache.values[func] == nil then
      cache.values[func] = {}
    end

    if cache.values[func][arg] == nil then
      cache.values[func][arg] = nvim.nvim_call_function(func, arg)
    end

    return cache.values[func][arg]
  else
    return nvim.nvim_call_function(func, arg)
  end
end


return cache
