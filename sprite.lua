local gl = require 'gl'
local memarray = require 'memarray'
local quaternion = require 'dokidoki.quaternion'
local vect = require 'dokidoki.vect'

local args = ...
transform = assert(args and args.transform or parent.transform)
color = args and args.color or false
scale = args and args.scale or false

local matrix = memarray('GLfloat', 16)
for i = 0, 14 do
  matrix[i] = 0
end
matrix[15] = 1

if resource then
  image = assert(game.resources and game.resources[resource],
                 "resource not found")
end
if not image then
  image = {
    draw = function ()
      gl.glBegin(gl.GL_QUADS)
      gl.glVertex2d(0, 0)
      gl.glVertex2d(1, 0)
      gl.glVertex2d(1, 1)
      gl.glVertex2d(0, 1)
      gl.glEnd()
    end
  }
end

function draw()
  local pos = transform.pos
  local orientation = self.transform.orientation
  local i = quaternion.rotated_i(orientation)
  local j = quaternion.rotated_j(orientation)
  local k = quaternion.rotated_k(orientation)

  local scale_x = scale and scale[1] or 1
  local scale_y = scale and scale[2] or 1
  local scale_z = scale and scale[3] or 1

  -- i
  matrix[0] = i[1] * scale_x
  matrix[1] = i[2] * scale_x
  matrix[2] = i[3] * scale_x
  -- j
  matrix[4] = j[1] * scale_y
  matrix[5] = j[2] * scale_y
  matrix[6] = j[3] * scale_y
  -- k
  matrix[8] = k[1] * scale_z
  matrix[9] = k[2] * scale_z
  matrix[10] = k[3] * scale_z

  -- translation
  matrix[12] = pos[1]
  matrix[13] = pos[2]
  matrix[14] = pos[3]

  gl.glPushMatrix()
  gl.glMultMatrixf(matrix:ptr())

  if color then
    gl.glColor4d(color[1], color[2], color[3], color[4] or 1)
  end
  gl.glNormal3d(0, 0, 1)
  image:draw()
  if color then gl.glColor3d(1, 1, 1) end

  gl.glPopMatrix()
end
