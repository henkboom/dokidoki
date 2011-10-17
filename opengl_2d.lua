using 'dokidoki'
local gl = require 'gl'

local opengl_2d = class(dokidoki.component)
opengl_2d._name = 'opengl_2d'

function opengl_2d:_init(parent)
  self:super(parent)
  self.background_color = {0, 0, 0}
  self.width = 640
  self.height = 480

  self:add_handler_for('predraw')
end

function opengl_2d:predraw()
  dokidoki.kernel.set_ratio(self.width / self.height)

  local bg = self.background_color
  if bg then
    gl.glClearColor(bg[1], bg[2], bg[3], 0)
    gl.glClear(gl.GL_COLOR_BUFFER_BIT)
  end

  gl.glEnable(gl.GL_BLEND)
  gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)
  gl.glAlphaFunc(gl.GL_GREATER, 0)
  gl.glEnable(gl.GL_ALPHA_TEST)

  gl.glMatrixMode(gl.GL_PROJECTION)
  gl.glLoadIdentity()
  gl.glOrtho(0, self.width, 0, self.height, 1, -1)
  gl.glMatrixMode(gl.GL_TEXTURE)
  gl.glLoadIdentity()
  gl.glMatrixMode(gl.GL_MODELVIEW)
  gl.glLoadIdentity()
end

return opengl_2d
