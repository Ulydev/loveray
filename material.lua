local class = require 'middleclass'

local Material = class('Material')

function Material:initialize(refractionIndex, albedo, diffuseColor, specularExponent)
  self.refractionIndex = refractionIndex
  self.albedo = albedo
  self.diffuseColor = diffuseColor
  self.specularExponent = specularExponent
end

return Material