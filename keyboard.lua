--- dokidoki.keyboard
--- ============================
---
--- Provides keyboard-input related information for the game.
---
--- Currently keys are identified by their GLFW key constants. For ascii
--- characters this is the character code, with letters always using the
--- upper-case value.

--- Implementation
--- --------------

using 'dokidoki'

local keyboard = class(dokidoki.component)
keyboard._name = 'keyboard'

local function bool(v)
  return not not v
end

function keyboard:_init(parent)
  self:super(parent)
  self._key_states = {}
  self._old_key_states = {}

  self:add_handler_for('postupdate')
  self:add_handler_for('handle_event')
end

--- ### `key_pressed(key)`
--- Returns true if `key` was pressed since the last frame, false otherwise.
function keyboard:key_pressed(key)
  return bool(self,_key_states[key] and not self._old_key_states[key])
end

--- ### `key_held(key)`
--- Returns true if `key` is currently down, false otherwise.
function keyboard:key_held(key)
  return bool(self._key_states[key])
end

--- ### `key_released(key)`
--- Returns true if `key` was released since the last frame, false otherwise.
function keyboard:key_released(key)
  return bool(not self._key_states[key] and self._old_key_states[key])
end

function keyboard:postupdate()
  self._old_key_states = dokidoki.base.copy(self._key_states)
end

function keyboard:handle_event(event)
  if event.type == 'key' then
    self._key_states[event.key] = event.is_down or nil
  end
end

return keyboard
