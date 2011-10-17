--- dokidoki.component
--- ==================

using 'dokidoki'

local component = class()
component._name = 'component'

function component:_init(parent)
  self.game = parent.game
  self.parent = parent
  self.removed = dokidoki.event()
  self.dead = false
  -- private
  self[component] = { subscriptions = {} }

  self.removed:add_handler(function ()
    for event,callback in pairs(self[component].subscriptions) do
      event:remove_handler(callback)
    end
  end)

  self.game:add_component(self)
end

function component:remove()
  self.game:remove_component(self)
end

function component:add_handler_for(event, callback)
  if type(event) == 'string' then
    if callback == nil then
      callback = event
    end
    event = self.game.events[event]
  end
  if type(callback) == 'string' then
    local method = self[callback]
    assert(method)
    callback = function(...) return method(self, ...) end
  end

  local subscriptions = self[component].subscriptions
  assert(subscriptions[event] == nil,
         "can't have two subscriptions to the same event")
  subscriptions[event] = callback
  event:add_handler(callback)
end

function component:remove_handler_for(event)
  local subscriptions = self[component].subscriptions
  event:remove_handler(subscriptions[event])
  subscriptions[event] = nil
end

return component
