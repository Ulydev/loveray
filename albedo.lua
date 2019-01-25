local class = require 'middleclass'

local Albedo = class('Albedo')

function Albedo:initialize(diffuse, specular, reflect, refract)
  self.diffuse = diffuse
  self.specular = specular
  self.reflect = reflect
  self.refract = refract
end

return Albedo