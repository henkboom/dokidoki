local vect = require 'dokidoki.vect'

local mt

local function make(w, x, y, z)
  return setmetatable({w, x, y, z}, mt)
end

local function from_rotation(axis, angle)
  local s = math.sin(angle/2)
  local c = math.cos(angle/2)
  return make(c, s * axis[1], s * axis[2], s * axis[3])
end

-- http://www.flipcode.com/documents/matrfaq.html#Q55
-- https://github.com/henkboom/rhizome/blob/master/quaternion.c#L39
local function from_ijk(axis, angle)
  assert(false)
end

local function look_at(direction, up)
  assert(false)
end

local function mul(a, b)
  return make(
    a[1]*b[1] - a[2]*b[2] - a[3]*b[3] - a[4]*b[4],
    a[1]*b[2] + a[2]*b[1] + a[3]*b[4] - a[4]*b[3],
    a[1]*b[3] + a[3]*b[1] + a[4]*b[2] - a[2]*b[4],
    a[1]*b[4] + a[4]*b[1] + a[2]*b[3] - a[3]*b[2])
end

local function sqrmag(q)
  return q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4]
end

local function mag(q)
  return math.sqrt(sqrmag(q))
end

local function norm(q)
  local sm = sqrmag(q)
  if(math.abs(sm - 1) > 0.000001) then
    local mag = math.sqrt(sm)
    return make(q[1]/mag, q[2]/mag, q[3]/mag, q[4]/mag)
  end
end

local function conjugate(q)
  return make(q[1], -q[2], -q[3], -q[4])
end

local function rotate_vect(q, v)
  local result = q * make(0, v[1], v[2], v[3]) * conjugate(q)
  return vect(result[2], result[3], result[4])
end

local function rotated_i(q)
  return vect(
    1 - 2*(q[3]*q[3] + q[4]*q[4]),
    2*(q[2]*q[3] + q[4]*q[1]),
    2*(q[2]*q[4] - q[3]*q[1]))
end

local function rotated_j(q)
  return vect(
    2*(q[2]*q[3] - q[4]*q[1]),
    1 - 2*(q[2]*q[2] + q[4]*q[4]),
    2*(q[3]*q[4] + q[2]*q[1]))
end

local function rotated_k(q)
  return vect(
    2*(q[2]*q[4] + q[3]*q[1]),
    2*(q[3]*q[4] - q[2]*q[1]),
    1 - 2*(q[2]*q[2] + q[3]*q[3]))
end

local function to_ijk_string(q)
  return
    '[i = ' .. rotated_i(q) ..
    ', j = ' .. rotated_j(q) ..
    ', k = ' ..  rotated_k(q) .. ']'
end

local function to_string(q)
  return
    'q(' .. q[1] .. ' + ' ..
    q[2] .. 'i + ' ..
    q[3] .. 'j + ' ..
    q[4] .. 'k)'

end

mt = {
  __mul = mul,
  __tostring = to_string
}

local identity = make(1, 0, 0, 0)

return setmetatable(
  {
    make = make,
    from_rotation = from_rotation,
    from_ijk = from_ijk,
    look_at = look_at,
    mul = mul,
    sqrmag = sqrmag,
    mag = mag,
    norm = norm,
    conjugate = conjugate,
    rotate_vect = rotate_vect,
    rotated_i = rotated_i,
    rotated_j = rotated_j,
    rotated_k = rotated_k,
    to_matrix = to_matrix,
    identity = identity,
    to_ijk_string = to_ijk_string,
    to_string = to_string,

  },
  {
    __call = function (_, ...) return make(...) end
  }
)
