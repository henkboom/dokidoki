local gl = require 'gl'

local args = ...
color = args.color or {1, 1, 1}
scale = args.scale or v2(1, 1) 

image = args.image
if not image then
  if args.resource then
    if not game.resources then
      error('no resources')
    end
    if not game.resources[args.resource] then
      error('resource not found: "' .. args.resource .. '"')
    end
    image = game.resources[args.resource]
  else
    -- create a dummy square if there's no given image
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
end

function draw()
  -- TODO: do these transforms directly, much faster!
  gl.glPushMatrix()
  gl.glTranslated(parent.transform.pos.x, parent.transform.pos.y, 0)
  -- slooooow and stupid rotation:
  local f = parent.transform.facing
  gl.glRotated(180/math.pi * math.atan2(f.y, f.x), 0, 0, 1)
  gl.glScaled(scale.x, scale.y, 1)

  gl.glColor4d(color[1], color[2], color[3], color[4] or 1)
  image:draw()
  gl.glColor3d(1, 1, 1)

  gl.glPopMatrix()
end
