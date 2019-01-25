local maf = require "maf"
require "util"

local Sphere = require "primitives.sphere"
local Material = require "material"
local Light = require "light"
local Albedo = require "albedo"
local Plane = require "primitives.plane"
local Disk = require "primitives.disk"
local Renderer = require "renderer"

local width, height = 1280, 720

love.window.setMode(width, height)

local renderer = Renderer:new(width, height, { drawDistance = 1000, renderScale = 1, maxDepth = 3 })

local image
local skybox = love.image.newImageData("skybox.png")

local ivory = Material:new(1.0, Albedo:new(0.6,  0.3, 0.1, 0.0), maf.vector(0.4, 0.4, 0.3), 50)
local redRubber = Material:new(1, Albedo:new(0.9,  0.1, 0.0, 0.0), maf.vector(0.3, 0.1, 0.1), 10)
local mirror = Material:new(1, Albedo:new(0.0, 10.0, 0.8, 0.0), maf.vector(1.0, 1.0, 1.0), 1425)
local glass = Material:new(1.5, Albedo:new(0.0, 0.5, 0.1, 0.8), maf.vector(0.6, 0.7, 0.8), 125)

function love.draw()
  
  local time = love.timer.getTime()
  
  local scene = {
    primitives = {
      Sphere:new(maf.vector(-3, 0, -16), 2, ivory),
      Sphere:new(maf.vector(-1, -1.5, -12), 2, glass),
      Sphere:new(maf.vector(1.5, -0.5, -18), 3, redRubber),
      Sphere:new(maf.vector(7, 5, -18), 4, mirror),
      Disk:new(maf.vector(0, -4, -10), maf.vector(0, 1), 5, mirror)
    },
    lights = {
      Light:new(maf.vector(-20, 20, 20), 1.5),
      Light:new(maf.vector(30, 50, -25), 1.8),
      Light:new(maf.vector(30, 20, 30), 1.7)
    },
    skybox = skybox
  }
  image = renderer:draw(scene)
  local dt = love.timer.getTime() - time
  print("Took " .. dt .. " seconds to render")
  
end