--- dokidoki.game
--- =============

--- Implementation
--- --------------

require "dokidoki.module" [[make_script, make_blueprint, make_game]]

import(require "dokidoki.base")

--- ### `make_script(name, init)`
--- Returns a new script with the given name and initialization function.
--- Whenever an instance of this script is to be initialized, `init` has its
--- environment set to be the script instance, so that any global variable
--- assignments are local to that script, and any initialization arguments are
--- available in the environment.
function make_script (name, init)
  return {name = name, init = init}
end

--- ### `make_blueprint(name, {script, key=value...}...)`
--- Returns a new blueprint with the given name and scripts. Each script can be
--- given a number of key-value pairs, which are stored as variables in the
--- script's environment. Variables set in `game.new()` take precedence over
--- these variables.
function make_blueprint(name, ...)
  return {name = name, ...}
end

--- ### `make_game(update_methods, draw_methods, init)`
--- Makes a game with the given update and draw phases. A scene for use with
--- `kernel.start_with_scene()` is returned, and during the first update `init`
--- is called with the game as a parameter.
function make_game (update_methods, draw_methods, init)
  local game = {}
  game.actors = {}

  local actors_by_tag = {}
  local scripts_by_method = {}

  scripts_by_method = {}
  scripts_by_method.handle_event = {}
  for _, method in ipairs(update_methods) do scripts_by_method[method] = {} end
  for _, method in ipairs(draw_methods) do scripts_by_method[method] = {} end

  game.make_script = make_script
  game.make_blueprint = make_blueprint

  -- delayed_require(name)
  -- Works like the regular require except that it returns a function
  -- representing the body of the module instead of running it. Also, if the
  -- module is not found, instead of signalling an error, nil and an error
  -- message are returned. Bypasses the global packages.loaded table for
  -- obvious reasons.
  local function delayed_require(name)
    local errors = {}
    for _, loader in ipairs(package.loaders) do
      local module = loader(name)
      if type(module) == 'function' then
        return module
      else
        table.insert(errors, module)
      end
    end
    return nil, table.concat(errors)
  end

  local function generic_load(kind, constructor, cache, prefixes, name)
    local errors = {}

    if not cache[name] then
      for _, prefix in ipairs(prefixes) do
        local thunk, err = delayed_require(prefix .. name)
        if thunk then
          cache[name] = constructor(name, thunk)
          break
        else
          table.insert(errors, err)
        end
      end
    end

    if not cache[name] then
      error('couldn\'t find requested ' .. kind .. ' "' .. name .. '"' ..
            table.concat(errors))
    end

    return cache[name]
  end

  -- load_script(name)
  -- Loads a script by name.
  local loaded_scripts = {}
  local script_prefixes = {'scripts.', 'dokidoki.scripts.'}
  local function load_script(name)
    return generic_load('script', make_script, loaded_scripts, script_prefixes,
                        name)
  end

  -- game.load_component(name)
  -- Loads a component by name.
  local loaded_components = {}
  local component_prefixes = {'components.', 'dokidoki.components.'}
  local function load_component(name)
    local function make_component(_, component) return component end
    return generic_load('component', make_component, loaded_components,
                        component_prefixes, name)
  end

  --- ### `game.init_component(name)`
  --- Loads and initializes the named component.
  function game.init_component(name)
    if game[name] ~= nil then
      error('name collision with component "' .. name .. '"')
    end

    local component = {game=game}
    game[name] = component

    local component_init = load_component(name)
    local env = getfenv(component_init)
    setfenv(component_init, setmetatable({}, {
      __index = function (_, k)
        local ret = component[k]
        if ret ~= nil then
          return ret
        else
          return env[k]
        end
      end,
      __newindex = function (_, k, v)
        component[k] = v
      end
    }))
    component_init(name)
    setfenv(component_init, env)
  end

  --- ### `game.actors.new(blueprint, {script, key=value...}...)`
  --- Instantiates a blueprint and adds the actor to the scene. Optionally,
  --- initialization arguments can be given to any script in the blueprint.
  --- These initialization arguments take precedence over the ones given in the
  --- blueprint definition.
  function game.actors.new(blueprint, ...)
    local arguments = {}
    for _, arg in ipairs{...} do
      local script = arg[1]
      if type(script) == 'string' then
        script = load_script(script)
      end
      arguments[script] = arg
    end

    local actor = {
      blueprint = blueprint,
      tags = {[blueprint.name] = true},
      dead = false,
      paused = false,
      hidden = false
    }

    for _, script_spec in ipairs(blueprint) do
      local script = script_spec[1]
      if type(script) == 'string' then
        script = load_script(script)
      end
      local script_name = script.name
      local script_init = script.init

      -- create script environment
      local script_env = {self = actor, game = game}

      -- add it to the actor, checking that there's no script collision
      if actor[script_name] ~= nil then
        error('script name collision for "' .. script_name .. "'")
      end
      actor[script_name] = script_env

      -- initialize default values from blueprint
      for k, v in pairs(script_spec) do
        if k ~= 1 then script_env[k] = v end
      end

      -- add constructor values
      if arguments[script] then
        for k, v in pairs(arguments[script]) do
          if k ~= 1 then script_env[k] = v end
        end
      end

      -- initialize the script

      -- the script's global environment is its table in the actor, chaining up
      -- to its original environment (usually the default global environment)
      --
      -- currently this is done using a dispatch function. this might be slow.
      --
      -- one alternative is to set the __index to be the script table itself,
      -- with the script table chaining to global. this would be faster but
      -- would expose the global environment through the script's table, which
      -- would be wierd.
      --
      -- another alternative is to add a reference to _G to the script table
      -- and not use chaining at all. this would probably be annoying for
      -- script writing though.
      local env = getfenv(script_init)
      setfenv(script_init, setmetatable({}, {
        __index = function (_, k)
          local ret = script_env[k]
          if ret ~= nil then
            return ret
          else
            return env[k]
          end
        end,
        __newindex = function (_, k, v)
          script_env[k] = v
        end
      }))
      script_init(script_name)
      setfenv(script_init, env)

      -- index the script by its methods
      for method, t in pairs(scripts_by_method) do
        if script_env[method] then t[#t+1] = script_env end
      end
    end

    -- index the actor by its tags
    for tag in pairs(actor.tags or {}) do
      actors_by_tag[tag] = actors_by_tag[tag] or {}
      table.insert(actors_by_tag[tag], actor)
    end

    return actor
  end

  --- ### `game.actors.new_generic(name, init)`
  --- Adds a simple one-script actor, with the script initializer given by
  --- `init`. This is a shortcut for creating a new blueprint with one script
  --- and then instantiating it. The generated actor will have `name` as its
  --- name, and a single script named `generic`.
  function game.actors.new_generic(name, init)
    return game.actors.new(
      make_blueprint(name, {make_script('generic', init)}))
  end

  --- ### `game.actors.get(tag)`
  --- Returns a list of the actors with the given tag. This is an internal data
  --- structure, so copy it if you need to make changes.
  function game.actors.get (tag)
    return actors_by_tag[tag] or {}
  end

  --- ### Scene Interface
  --- The next few functions handle dispatching kernel callbacks to all
  --- applicable actors. They aren't accessible from the game object, only from
  --- the scene object returned by `make_game()`.

  local function handle_event (event)
    for _, a in ipairs(scripts_by_method.handle_event) do
      a.handle_event(event)
    end
  end

  local function update (dt)
    -- initialize
    if init then
      init(game)
      init = false
    end

    -- update all actors
    for _, update_type in ipairs(update_methods) do
      for _, script in ipairs(scripts_by_method[update_type]) do
        if not script.self.dead and not script.self.paused then
          script[update_type]() end
      end
    end

    -- cull dead actors
    for k, _ in pairs(scripts_by_method) do
      scripts_by_method[k] =
        ifilter(function (s) return not s.self.dead end, scripts_by_method[k])
    end
    for k, _ in pairs(actors_by_tag) do
      actors_by_tag[k] =
        ifilter(function (a) return not a.dead end, actors_by_tag[k])
    end
  end

  local function draw ()
    for _, draw_type in ipairs(draw_methods) do
      for _, script in ipairs(scripts_by_method[draw_type]) do
        if not script.self.hidden then
          script[draw_type]()
        end
      end
    end
  end

  -- return the scene interface for the kernel's main loop
  return { handle_event = handle_event, update = update, draw = draw }
end

return get_module_exports()
