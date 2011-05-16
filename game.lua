--- dokidoki.game
--- =============

--- Implementation
--- --------------

require "dokidoki.module" [[make_game]]

import(require "dokidoki.base")

--- ### `make_game(update_methods, draw_methods, init, init_args...)`
--- Makes a game with the given update and draw phases. A scene for use with
--- `kernel.start_with_scene()` is returned. During the first update the
--- component named by `init` is initialized as the root, with `init_args...`
--- as its arguments.
function make_game (update_methods, draw_methods, init, ...)
  local game = {}
  local init_args = {n = select('#', ...), ...}

  -- all active components
  local components = {}

  -- map callback names to lists of subscribing components
  local components_by_callback = {handle_event = {}}
  for _, method in ipairs(update_methods) do
    components_by_callback[method] = {}
  end
  for _, method in ipairs(draw_methods) do
    components_by_callback[method] = {}
  end

  -- component-keyed set of components queued for removal
  local components_to_remove = {}


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

  --- ### `game.add_component(parent, component_type, component_args...)`
  --- Adds a new child component to the component `parent`. `component_type` is
  --- the name of a module to use as the constructor. `component_args...` are
  --- passed through as arguments to this constructor.
  function game.add_component(parent, component_type, ...)
    -- If the parent is nil then we are initializing the root node, which is
    -- the game object itself. This happens once internally and then never
    -- again.

    -- If the game has been initialized then there must be a parent.
    if game.game then
      assert(parent, 'game.add_component: must have a parent')
    end
    assert(component_type == nil or type(component_type) == 'string',
           'game.add_component: if given, component_type must be a string')

    local component = parent == nil and game or {}
    component.game = game
    component.parent = parent
    component.self = component
    component.type = component_type

    -- add the component to the component list, must be done before calling
    -- constructor because the constructor might call add_component again
    components[#components+1] = component

    if component_type then
      -- call the constructor in the construction environment
      local constructor = load_module(component_type)
      local env = getfenv(constructor)
      debug.setfenv(constructor, setmetatable({}, {
        -- lookups chain from the component to its environment
        __index = function (_, k)
          local ret = component[k]
          if ret ~= nil then
            return ret
          else
            return env[k]
          end
        end,
        -- assignments go directly to the component
        __newindex = function(_, k, v)
          component[k] = v
        end
      }))
      constructor(...)
      -- reset the environment for next time
      debug.setfenv(constructor, env)
    end

    -- index by method
    for method, t in pairs(components_by_callback) do
      if component[method] then
        t[#t+1] = component
      end
    end

    return component
  end

  --- ### `game.remove_component(component)`
  --- Queues `component` for removal after the current update. Removed
  --- components will also have the field `dead` set to true.
  function game.remove_component(component)
    components_to_remove[component] = true
  end

  --- ### Scene Interface
  --- The next few functions handle dispatching kernel callbacks to all
  --- applicable actors. They aren't accessible from the game object, only from
  --- the scene object returned by `make_game()`.

  local function handle_event (event)
    for _, a in ipairs(components_by_callback.handle_event) do
      a.handle_event(event)
    end
  end

  local function update (dt)
    -- initialize
    if init then
      game.add_component(nil, init, unpack(init_args, 1, init_args.n))
      init = false
      init_args = nil
    end

    -- update all actors
    for _, update_method in ipairs(update_methods) do
      local components_to_update = components_by_callback[update_method]
      for i = 1, #components_to_update do
        components_to_update[i][update_method]()
      end
    end

    -- process actor removals
    if next(components_to_remove) ~= nil then
      -- transitive closure
      for i = 1, #components do
        local component = components[i]
        if components_to_remove[component.parent] then
          components_to_remove[component] = true
        end
        if components_to_remove[component] then
          if component.on_removal then
            component.on_removal()
          end
          component.dead = true
        end
      end

      -- cull out the removed components
      components = ifilter(
        function (component) return not components_to_remove[component] end,
        components)
      for k, _ in pairs(components_by_callback) do
        components_by_callback[k] = ifilter(
          function (component) return not components_to_remove[component] end,
          components_by_callback[k])
      end

      components_to_remove = {}

    end

    if #components == 0 then
      kernel.abort_main_loop()
    end
  end

  local function draw ()
    for _, draw_method in ipairs(draw_methods) do
      local components_to_draw = components_by_callback[draw_method]
      for i = 1,  #components_to_draw do
        components_to_draw[i][draw_method]()
      end
    end
  end

  -- return the scene interface for the kernel's main loop
  return { handle_event = handle_event, update = update, draw = draw }
end

return get_module_exports()
