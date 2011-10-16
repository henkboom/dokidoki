--- dokidoki.exit_handler
--- ================================
---
--- Allows an action to be taken when an exit event is received.
---
--- By default the root component is removed, causing the game to end, provide
--- another value of `on_close` to do something else:
---
---
---     function game.exit_handler.on_close()
---       -- do something
---     end
---
--- If you set the argument `exit_on_esc` to `true`, the callback will also be
--- called when the player presses the escape button.

--- Implementation
--- --------------

using 'dokidoki'
require 'glfw'

local exit_handler = class(dokidoki.component)
exit_handler._name = 'exit_handler'

function exit_handler:_init(parent)
  self:super(parent)
  self.on_close = dokidoki.kernel.abort_main_loop
  self.exit_on_esc = false

  self:add_handler_for('handle_event')
end

function exit_handler:handle_event(event)
  if event.type == 'quit' or
     (self.exit_on_esc and event.type == 'key' and event.is_down and
      event.key == glfw.KEY_ESC) then
    self.on_close()
  end
end

return exit_handler
