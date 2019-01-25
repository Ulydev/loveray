local Plane = require 'primitives.plane'

local Disk = Plane:subclass('Disk')

function Disk:initialize(center, normal, radius, material)
  Plane.initialize(self, center, normal, material)
  self.radius = radius
end

function Disk:intersectsRay(origin, direction)
  local intersects, distance, point, normal = Plane.intersectsRay(self, origin, direction)
  if not intersects then return false end

  local r = #(self.center - point)
  if (r * r > self.radius * self.radius) then return false end
  
  return intersects, distance, point, normal
end

return Disk