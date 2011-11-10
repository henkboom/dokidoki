using 'pl'
using 'dokidoki'
local vect = require 'dokidoki.vect'
local quaternion = require 'dokidoki.quaternion'

local transform = pl.class()
transform._name = 'transform'

function transform:_init(pos, orientation)
  self.pos = pos or vect.zero
  self.orientation = orientation or quaternion.identity
end

return transform
