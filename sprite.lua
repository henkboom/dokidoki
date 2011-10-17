using 'pl'
using 'dokidoki'
local gl = require 'gl'
local graphics = require 'dokidoki.graphics'

local matrix = memarray('GLfloat', 16)
for i = 0, 14 do
  matrix[i] = 0
end
matrix[15] = 1

local box_image = {
  draw = function ()
    gl.glBegin(gl.GL_QUADS)
    gl.glVertex2d(0, 0)
    gl.glVertex2d(1, 0)
    gl.glVertex2d(1, 1)
    gl.glVertex2d(0, 1)
    gl.glEnd()
  end
}

local sprite = pl.class(dokidoki.component)
sprite._name = 'sprite'

function sprite:_init(parent, transform)
  self:super(parent)
  self.transform = assert(transform or parent.transform)
  self.image = box_image
  self.color = false
  self.scale = false

  self:add_handler_for('draw')
end

function sprite:draw()
  local pos = self.transform.pos
  local orientation = self.transform.orientation
  local i = quaternion.rotated_i(orientation)
  local j = quaternion.rotated_j(orientation)
  local k = quaternion.rotated_k(orientation)

  local scale_x = self.scale and self.scale[1] or 1
  local scale_y = self.scale and self.scale[2] or 1
  local scale_z = self.scale and self.scale[3] or 1

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
  graphics.apply_transform(transform.pos, transform.orientation, scale)

  if self.color then
    gl.glColor4d(color[1], color[2], color[3], color[4] or 1)
  end
  gl.glNormal3d(0, 0, 1)
  self.image:draw()
  if self.color then gl.glColor3d(1, 1, 1) end

  gl.glPopMatrix()
end

return sprite
