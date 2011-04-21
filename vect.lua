require "dokidoki.module"
[[ make,
   add, sub, neg, mul, div, dot, cross, rotate, project,
   mag, sqrmag, norm, eq, coords, is_small,
   zero, i, j, k ]]

function make (x, y, z)   return setmetatable({x, y, z or 0}, mt) end
local make = make

function add (a, b)    return make(a[1]+b[1], a[2]+b[2], a[3]+b[3]) end
function sub (a, b)    return make(a[1]-b[1], a[2]-b[2], a[3]-b[3]) end
function neg (v)       return make(-v[1], -v[2], -v[3]) end
function mul (v, s)    return make(s*v[1], s*v[2], s*v[3]) end
function div (v, s)    return make(v[1]/s, v[2]/s, v[3]/s) end
function dot (a, b)    return a[1]*b[1] + a[2]*b[2] + a[3]*b[3] end
function project(a, b) return b * (dot(a, b) / sqrmag(b)) end

function mag (v)    return math.sqrt(sqrmag(v)) end
function sqrmag (v) return dot(v, v) end
function norm (v)   return v / mag(v) end
function eq (a, b)  return a[1]==b[1] and a[2]==b[2] and a[3]==b[3] end
function coords (v) return v[1], v[2], v[3] end

function cross (a, b)
  return make(
    a[2]*b[3]-a[3]*b[2],
    a[3]*b[1]-a[1]*b[3],
    a[1]*b[2]-a[2]*b[1])
end

function rotate(v, axis, angle)
  local q0 = math.cos(angle/2)
  local s = math.sin(angle/2)
  local q1 = s * axis[1]
  local q2 = s * axis[2]
  local q3 = s * axis[3]
  return make(
    ((q0*q0 + q1*q1 - q2*q2 - q3*q3) * v[1] +
     2*(q1*q2 - q0*q3) * v[2] +
     2*(q1*q3 + q0*q2) * v[3]),
    (2*(q2*q1 + q0*q3) * v[1] +
     (q0*q0 - q1*q1 + q2*q2 - q3*q3) * v[2] +
     2*(q2*q3 - q0*q1) * v[3]),
    (2*(q3*q1 - q0*q2) * v[1] +
     2*(q3*q2 + q0*q1) * v[2] +
     (q0*q0 - q1*q1 - q2*q2 + q3*q3) * v[3]))
end

function is_small(v)
  return sqrmag(v) <= 0.00001
end

mt =
{
  __add = add,
  __sub = sub,
  __mul = function (a, b)
    return type(a) == 'number' and mul(b, a) or mul(a, b)
  end,
  __div = div,
  __unm = neg,
  __eq = eq,

  __tostring = function (v)
    return '(' .. v[1] .. ', ' .. v[2] .. ', ' .. v[3] .. ')'
  end,
}

zero = make(0, 0, 0)
i = make(1, 0, 0)
j = make(0, 1, 0)
k = make(0, 0, 1)

return setmetatable(
  get_module_exports(),
  {__call = function (_, ...) return make(...) end})
