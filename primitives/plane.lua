local Primitive = require 'primitives.primitive'

local Plane = Primitive:subclass('Plane')

function Plane:initialize(center, normal, material)
  self.center = center
  self.normal = normal:normalize()
  self.material = material
end

function Plane:intersectsRay(origin, direction)
  local denom = self.normal:dot(direction)
  if (math.abs(denom) < 0.0001) then
    return false
  end
  
  local distance = (self.center - origin):dot(self.normal) / denom
  if distance < 0 then return false end
  
  local point = origin + direction * distance
  return true, distance, point, -self.normal * math.sign(denom)
end

return Plane