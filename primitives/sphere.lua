local Primitive = require 'primitives.primitive'

local Sphere = Primitive:subclass('Sphere')

function Sphere:initialize(center, radius, material)
  self.center = center
  self.radius = radius
  self.material = material
end

function Sphere:intersectsRay(origin, direction)
  local l = self.center - origin
  local tca = l:dot(direction)
  local d2 = l:dot(l) - tca * tca
  if (d2 > self.radius * self.radius) then return false end
  local thc = math.sqrt(self.radius * self.radius - d2)
  local distance = tca - thc
  local t1 = tca + thc
  if (distance < 0) then distance = t1 end
  if (distance < 0) then return false end
  
  local point = origin + direction * distance
  return true, distance, point, (point - self.center):normalize()
end

return Sphere