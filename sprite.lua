using 'pl'
using 'dokidoki'
local graphics = dokidoki.graphics
local quaternion = dokidoki.quaternion
local gl = require 'gl'

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
  gl.glPushMatrix()
  graphics.apply_transform(
    self.transform.pos, self.transform.orientation, self.scale)

  if self.color then
    gl.glColor4d(color[1], color[2], color[3], color[4] or 1)
  end
  gl.glNormal3d(0, 0, 1)
  self.image:draw()
  if self.color then gl.glColor3d(1, 1, 1) end

  gl.glPopMatrix()
end

return sprite
