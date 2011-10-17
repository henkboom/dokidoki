using 'dokidoki'

-- compatibility layer for old components

---- utilities ----------------------------------------------------------------

-- load_module(name)
-- Like `loadfile` except that it uses `package.loaders` to look up the
-- module like `require`.
local module_cache = {}
local function load_module(name)
  if not module_cache[name] then
    local errors = {}
    for _, loader in ipairs(package.loaders) do
      local module = loader(name)
      if type(module) == 'function' then
        module_cache[name] = module
        return module
      else
        table.insert(errors, module)
      end
    end
    error('couldn\'t find component "' .. name .. '": ' ..
          table.concat(errors))
  end
  return module_cache[name]
end

---- retro_component ----------------------------------------------------------

local retro_component = class(dokidoki.component)
retro_component._name = 'component'

function retro_component:_init(parent, component_type, ...)
  self:super(parent)
  self.self = self
  self.type = component_type
  if component_type then
    -- call the constructor in the construction environment
    local constructor = load_module(component_type)
    local env = getfenv(constructor)
    local component_env = {
      game = setmetatable({
        add_component = function (parent, component_type, ...)
          return retro_component(parent, component_type, ...)
        end,
        remove_component = function ()
          game:remove_component(self)
        end
      }, {__index = self.game})
    }
    debug.setfenv(constructor, setmetatable(component_env, {
      -- lookups chain from the component to its environment
      __index = function (_, k)
        local ret = self[k]
        if ret ~= nil then
          return ret
        else
          return env[k]
        end
      end,
      -- assignments go directly to the component
      __newindex = function(_, k, v)
        self[k] = v
      end
    }))
    constructor(...)
    -- reset the environment for next time
    debug.setfenv(constructor, env)
  end

  for name, event in pairs(self.game.events) do
    if self[name] ~= nil then
      self:add_handler_for(event, function (...) self[name](...) end)
    end
  end
end

return retro_component
