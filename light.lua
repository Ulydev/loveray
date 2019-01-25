local class = require 'middleclass'

local Light = class('Light')

function Light:initialize(position, intensity)
  self.position = position
  self.intensity = intensity
end

return Light