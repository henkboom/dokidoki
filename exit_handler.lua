--- dokidoki.components.exit_handler
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

local kernel = require 'dokidoki.kernel'
require 'glfw'

local args = ...
on_close = args.on_close or kernel.abort_main_loop
exit_on_esc = args.exit_on_esc or false

function handle_event(event)
  if event.type == 'quit' or
     (exit_on_esc and event.type == 'key' and event.is_down and
      event.key == glfw.KEY_ESC) then
    on_close()
  end
end
