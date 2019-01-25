local maf = require "maf"
require "util"

local Sphere = require "primitives.sphere"
local Material = require "material"
local Light = require "light"
local Albedo = require "albedo"
local Plane = require "primitives.plane"
local Disk = require "primitives.disk"

local width, height = 1280, 720
local scale = 1
local MAX_DRAW_DISTANCE = 1000

love.window.setMode(width, height)

local backgroundColor = maf.vector(.2, .6, .9)

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

local function castRay(origin, direction, primitives, lights, skybox, depth)
  depth = depth or 0
  
  local hit = sceneIntersectsRay(origin, direction, primitives)
  if (depth <= 4 and hit and hit.distance < MAX_DRAW_DISTANCE) then
    local reflectDirection = reflect(direction, hit.normal):normalize()
    local refractDirection = refract(direction, hit.normal, hit.material.refractionIndex):normalize()
    local reflectOrigin = reflectDirection:dot(hit.normal) < 0 and (hit.point - hit.normal * 0.001) or (hit.point + hit.normal * 0.001)
    local refractOrigin = refractDirection:dot(hit.normal) < 0 and (hit.point - hit.normal * 0.001) or (hit.point + hit.normal * 0.001)
    local reflectColor = castRay(reflectOrigin, reflectDirection, primitives, lights, skybox, depth + 1)
    local refractColor = castRay(refractOrigin, refractDirection, primitives, lights, skybox, depth + 1)
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

local function render(width, height, primitives, lights, skybox)
  
  local data = love.image.newImageData(width, height)
  
  local fov = math.pi / 2
  
  for x = 0, width - 1 do
    for y = 0, height - 1 do
      local dx = (2 * (x + 0.5) / width - 1) * math.tan(fov / 2) * width / height
      local dy = -(2 * (y + 0.5) / height - 1) * math.tan(fov / 2)
      local direction = maf.vector(dx, dy, -1):normalize()
      local color = castRay(maf.vector(0, 0, 0), direction, primitives, lights, skybox)
      data:setPixel(x, y, color.x, color.y, color.z)
    end
  end
  
  return love.graphics.newImage(data)
  
end

local image
local skybox = love.image.newImageData("skybox.png")

local ivory = Material:new(1.0, Albedo:new(0.6,  0.3, 0.1, 0.0), maf.vector(0.4, 0.4, 0.3), 50)
local redRubber = Material:new(1, Albedo:new(0.9,  0.1, 0.0, 0.0), maf.vector(0.3, 0.1, 0.1), 10)
local mirror = Material:new(1, Albedo:new(0.0, 10.0, 0.8, 0.0), maf.vector(1.0, 1.0, 1.0), 1425)
local glass = Material:new(1.5, Albedo:new(0.0, 0.5, 0.1, 0.8), maf.vector(0.6, 0.7, 0.8), 125)

function love.draw()
  
  local time = love.timer.getTime()
  image = render(width * scale, height * scale, {
      Sphere:new(maf.vector(-3, 0, -16), 2, ivory),
      Sphere:new(maf.vector(-1, -1.5, -12), 2, glass),
      Sphere:new(maf.vector(1.5, -0.5, -18), 3, redRubber),
      Sphere:new(maf.vector(7, 5, -18), 4, mirror),
      Disk:new(maf.vector(0, -4, -10), maf.vector(0, 1), 5, mirror)
    }, {
      Light:new(maf.vector(-20, 20, 20), 1.5),
      Light:new(maf.vector(30, 50, -25), 1.8),
      Light:new(maf.vector(30, 20, 30), 1.7)
    }, skybox)
  local dt = love.timer.getTime() - time
  print("Took " .. dt .. " seconds to render")
  
  love.graphics.draw(image, 0, 0, 0, 1 / scale, 1 / scale)
  
end