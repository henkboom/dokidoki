using 'pl'
using 'dokidoki'
local vect = require 'dokidoki.vect'
local quaternion = require 'dokidoki.quaternion'

local transform = pl.class()
transform._name = 'transform'

function transform:_init()
  self.pos = vect.zero
  self.orientation = quaternion.identity
end

return transform
