local gl = require 'gl'
local graphics = require 'dokidoki.graphics'

local args = ...
transform = assert(args and args.transform or parent.transform)
color = args and args.color or false
scale = args and args.scale or false

if args and args.resource then
  image = assert(game.resources and game.resources[args.resource],
                 "resource not found")
elseif args and args.image then
  image = args.image
else
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
  gl.glPushMatrix()
  graphics.apply_transform(transform.pos, transform.orientation, scale)

  if color then
    gl.glColor4d(color[1], color[2], color[3], color[4] or 1)
  end
  gl.glNormal3d(0, 0, 1)
  image:draw()
  if color then gl.glColor3d(1, 1, 1) end

  gl.glPopMatrix()
end
