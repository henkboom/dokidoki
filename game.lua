--- dokidoki.game
--- =============

using 'pl'
using 'dokidoki'

game = pl.class(dokidoki.component)
game._name = 'game'

function game:_init(update_events, draw_events)
  self.game = self

  ---- events ----
  -- ordered
  self.update_events = {}
  self.draw_events = {}
  -- by name
  self.events = { handle_event = dokidoki.event() }

  -- fill them in
  for i = 1, #update_events do
    local e = dokidoki.event()
    self.events[update_events[i]] = e
    self.update_events[i] = e
  end
  for i = 1, #draw_events do
    local e = dokidoki.event()
    self.events[draw_events[i]] = e
    self.draw_events[i] = e
  end

  ---- components ----
  self.components = {}
  self._components_to_start = {}
  self._components_to_remove = {}

  self.init_callback = false

  -- self:super calls game:add_component, so we need to call this last
  self:super(self)
  self.parent = false
end

function game:start_main_loop(init)
  self.init_callback = init

  dokidoki.kernel.start_main_loop{
    update = function (...) return self:_update(...) end,
    draw = function (...) return self:_draw(...) end,
    handle_event = function (...) return self:_handle_event(...) end
  }
end

function game:add_component(child)
  table.insert(self.components, child)
  if child._start then
    table.insert(self._components_to_start, child)
  end
end

function game:remove_component(component_to_remove)
  assert(not component_to_remove.dead, 'tried to remove dead component')
  self._components_to_remove[component_to_remove] = true
end

local function not_dead(c) return not c.dead end

function game:_start_new_components()
  while #self._components_to_start > 0 do
    local components_to_start = self._components_to_start
    self._components_to_start = {}

    for i = 1, #components_to_start do
      if not components_to_start[i].dead then
        components_to_start[i]:_start()
      end
    end
  end
end

function game:_update()
  if self.init_callback then
    self.init_callback()
    self.init_callback = false
  end

  for i = 1, #self.update_events do
    self:_start_new_components()
    self.update_events[i]()
  end

  if next(self._components_to_remove) ~= nil then
    -- transitive closure forwards
    for i = 1, #self.components do
      local component = self.components[i]
      if self._components_to_remove[component.parent] then
        self._components_to_remove[component] = true
      end
    end
    -- delete nodes reverse order (children first)
    for i = #self.components, 1, -1 do
      local component = self.components[i]
      if self._components_to_remove[component] then
        self._components_to_remove[component] = nil
        component.removed()
        component.dead = true
      end
    end

    dokidoki.base.ifilter_in_place(not_dead, self.components)

    if self.dead then
      kernel.abort_main_loop()
    end
  end
end

function game:_draw()
  for i = 1, #self.draw_events do
      self.draw_events[i]()
  end
end

function game:_handle_event(e)
  self.events.handle_event(e)
end

return game
