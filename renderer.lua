local class = require "middleclass"
local maf = require "maf"

local Renderer = class("Renderer")

function Renderer:initialize(width, height, properties)
  self.width, self.height = width, height
  self.properties = properties
  
  local scale = properties.renderScale
  self.output = love.image.newImageData(width * scale, height * scale)
end


local function sceneIntersectsRay(origin, direction, primitives)
  local hit = false
  for i = 1, #primitives do
    local primitive = primitives[i]
    local intersects, distance, point, normal = primitive:intersectsRay(origin, direction)
    if (intersects == true and (not hit or distance < hit.distance)) then
      hit = {
        distance = distance,
        point = point,
        normal = normal,
        material = primitive.material
      }
    end
  end
  return hit
end

local function reflect(i, n)
  return i - n * 2 * i:dot(n)
end

local function refract(i, n, refractionIndex)
  local cosi = -math.max(-1, math.min(1, i:dot(n)))
  local etai, etat = 1, refractionIndex
  if (cosi < 0) then
    cosi = -cosi
    etai, etat = etat, etai
    n = -n
  end
  eta = etai / etat
  local k = 1 - eta * eta * (1 - cosi * cosi)
  return k < 0 and maf.vector(0, 0, 0) or (i * eta + n * (eta * cosi - math.sqrt(k)))
end

function Renderer:castRay(origin, direction, primitives, lights, skybox, depth)
  depth = depth or 0
  
  local hit = sceneIntersectsRay(origin, direction, primitives)
  if (depth <= self.properties.maxDepth and hit and hit.distance < self.properties.drawDistance) then
    local reflectDirection = reflect(direction, hit.normal):normalize()
    local refractDirection = refract(direction, hit.normal, hit.material.refractionIndex):normalize()
    local reflectOrigin = reflectDirection:dot(hit.normal) < 0 and (hit.point - hit.normal * 0.001) or (hit.point + hit.normal * 0.001)
    local refractOrigin = refractDirection:dot(hit.normal) < 0 and (hit.point - hit.normal * 0.001) or (hit.point + hit.normal * 0.001)
    local reflectColor = self:castRay(reflectOrigin, reflectDirection, primitives, lights, skybox, depth + 1)
    local refractColor = self:castRay(refractOrigin, refractDirection, primitives, lights, skybox, depth + 1)
    local diffuseLightIntensity, specularLightIntensity = 0, 0
    for i = 1, #lights do
      local light = lights[i]
      local lightDirection = (light.position - hit.point):normalize()
      local lightDistance = #(light.position - hit.point)
      local shadowOrigin = lightDirection:dot(hit.normal) < 0 and (hit.point - hit.normal * 0.001) or (hit.point + hit.normal * 0.001)
      local shadowHit = sceneIntersectsRay(shadowOrigin, lightDirection, primitives)
      if not (shadowHit and #(shadowHit.point - shadowOrigin) < lightDistance) then
        diffuseLightIntensity = diffuseLightIntensity + light.intensity * math.max(0, lightDirection:dot(hit.normal))
        specularLightIntensity = specularLightIntensity + math.pow(math.max(0, -reflect(-lightDirection, hit.normal):dot(direction)), hit.material.specularExponent) * light.intensity
      end
    end
    return hit.material.diffuseColor * diffuseLightIntensity * hit.material.albedo.diffuse + maf.vector(1, 1, 1) * specularLightIntensity * hit.material.albedo.specular + reflectColor * hit.material.albedo.reflect + refractColor * hit.material.albedo.refract
  else
    local normalized = direction:normalize()
    local r, g, b = skybox:getPixel(math.floor(((normalized.x / 2 + .5) % 1) * skybox:getWidth()), math.floor(((-normalized.y / 2 + .5) % 1) * skybox:getHeight()))
    return maf.vector(r, g, b)
  end
end

function Renderer:render(scene)
  local primitives = scene.primitives
  local lights = scene.lights
  local skybox = scene.skybox
  
  self.fov = math.pi / 2
  
  local scale = self.properties.renderScale
  local width, height = self.width * scale, self.height * scale
  
  for x = 0, width - 1 do
    for y = 0, height - 1 do
      local dx = (2 * (x + 0.5) / width - 1) * math.tan(self.fov / 2) * width / height
      local dy = -(2 * (y + 0.5) / height - 1) * math.tan(self.fov / 2)
      local direction = maf.vector(dx, dy, -1):normalize()
      local color = self:castRay(maf.vector(0, 0, 0), direction, primitives, lights, skybox)
      self.output:setPixel(x, y, color.x, color.y, color.z)
    end
  end
  
  return love.graphics.newImage(self.output)
  
end

function Renderer:draw(scene)
  local scale = self.properties.renderScale
  love.graphics.draw(self:render(scene), 0, 0, 0, 1 / scale, 1 / scale)
end

return Renderer