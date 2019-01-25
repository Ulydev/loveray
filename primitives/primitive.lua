local class = require 'middleclass'

local Primitive = class('Primitive')

function Primitive:intersectsRay(origin, direction, distance)
  assert(false, "Not implemented")
end

return Primitive