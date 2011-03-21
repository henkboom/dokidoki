--- dokidoki.components.keyboard
--- ============================
---
--- Provides keyboard-input related information for the game.
---
--- Currently keys are identified by their GLFW key constants. For ascii
--- characters this is the character code, with letters always using the
--- upper-case value.

--- Implementation
--- --------------

local base = require 'dokidoki.base'

local key_states = {}
local old_key_states = {}

--- ### `key_pressed(key)`
--- Returns true if `key` was pressed since the last frame, false otherwise.
function key_pressed(key)
  return not not (key_states[key] and not old_key_states[key])
end

--- ### `key_held(key)`
--- Returns true if `key` is currently down, false otherwise.
function key_held(key)
  return not not key_states[key]
end

--- ### `key_released(key)`
--- Returns true if `key` was released since the last frame, false otherwise.
function key_released(key)
  return not not (not key_states[key] and old_key_states[key])
end

function postupdate()
  old_key_states = base.copy(key_states)
end

function handle_event(event)
  if event.type == 'key' then
    key_states[event.key] = event.is_down or nil
  end
end
