local vect = require 'dokidoki.vect'
local quaternion = require 'dokidoki.quaternion'

local args = ...
pos = args and args.pos or vect(0, 0, 0)
orientation = args and args.orientation or quaternion.identity
