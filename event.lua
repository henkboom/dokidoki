--- dokidoki.event
--- ==============

using 'pl'

local event = class()

function event:_init()
  self._count = 0 -- number of handlers
  self._length = 0 -- length of sparse array
  self._indices = {} -- handler->index
  self._handlers = {} -- list of handlers
end

function event:__call(...)
  local handlers = self._handlers
  for i = 1, self._length do
    local f = handlers[i]
    if f ~= nil then
      f(...)
    end
  end
end

function event:add_handler(f)
  assert(f ~= nil, 'tried to add a nil handler')
  assert(self._indices[f] == nil, 'two of the same handler added to one event')
  self._length = self._length + 1
  self._count = self._count + 1

  self._handlers[self._length] = f
  self._indices[f] = self._length
end

local function filter_out_nils_in_place(t, length)
  local src = 1
  while src <= length and t[src] ~= nil do
    -- [1..src) were already compacted
    -- [src..length] left to check
    src = src + 1
  end
  -- [1..src) were already compacted
  -- [src..length] left to compact
  local dest = src
  while src <= length do
    -- [1..dest) compacted
    -- [src..length] to compact
    if t[src] ~= nil then
      t[dest] = t[src]
      dest = dest + 1
    end
    src = src + 1
  end
  -- [1, dest) compacted
  -- [dest, length] garbage to nil out
  while dest <= length do
    t[dest] = nil
    dest = dest + 1
  end
end

function event:remove_handler(f)
  local handlers = self._handlers
  local indices = self._indices

  assert(f ~= nil)
  assert(indices[f] ~= nil, 'removing handler that isn\'t on this event')

  handlers[indices[f]] = nil
  indices[f] = nil
  self._count = self._count - 1

  if self._count < self._length/2 then
    filter_out_nils_in_place(handlers, self._length)
    self._length = self._count

    for i = 1, #handlers do
      indices[handlers[i]] = i
    end

    assert(self._length == #handlers)
  end
end

return event
