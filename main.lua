if arg[2] == "debug" then
    require("lldebugger").start()
end

local wizard 
local gameMap

local squares

function love.load()
    sti = require('lib/sti')
    -- gameMap = sti('maps/floor example.lua')

    camera = require('lib/camera')
    cam1 = camera()

    anim8 = require('lib/anim8')
    love.graphics.setDefaultFilter('nearest', 'nearest')

    squares = 16

    wizard = {}
    wizard.x = 5 * squares
    wizard.y = 3 * squares
    wizard.speed = 32
    wizard.scale = 2
    wizard.spriteSheet = love.graphics.newImage('sprites/player/wizard.png')
    wizard.grid = anim8.newGrid(
        16,
        32,
        wizard.spriteSheet:getWidth(),
        wizard.spriteSheet:getHeight()
    )

    wizard.animation = {}
    wizard.animation.down  = anim8.newAnimation(wizard.grid('1-4', 1), 0.15)
    wizard.animation.left  = anim8.newAnimation(wizard.grid('5-8', 1), 0.15)
    wizard.animation.up    = anim8.newAnimation(wizard.grid('9-12', 1), 0.15)
    wizard.animation.right = anim8.newAnimation(wizard.grid('13-16', 1), 0.15)

    wizard.currentAnimation = wizard.animation.up

end

function love.update(dt)
    local vectorX = 0
    local vectorY = 0

    if love.keyboard.isDown("right") then
        vectorX = vectorX + 1
        wizard.currentAnimation = wizard.animation.right
    end
    if love.keyboard.isDown("left") then
        vectorX = vectorX - 1
        wizard.currentAnimation = wizard.animation.left
    end
    if love.keyboard.isDown("down") then
        vectorY = vectorY + 1
        wizard.currentAnimation = wizard.animation.down
    end
    if love.keyboard.isDown("up") then
        vectorY = vectorY - 1
        wizard.currentAnimation = wizard.animation.up
    end
    -- stand still if not moving 
    if vectorX == 0 and vectorY == 0 then
        wizard.currentAnimation:gotoFrame(2)
    -- normalize speed
    elseif vectorX ~= 1 and vectorY ~= 1 then 
        vectorX = vectorX * .707
        vectorY = vectorY * .707
    end

    wizard.x = wizard.x + (vectorX * wizard.speed * dt)
    wizard.y = wizard.y + (vectorY * wizard.speed * dt)

    wizard.currentAnimation:update(dt)
end


function love.draw() 
    cam1:attach()
    --gameMap:drawLayer(gameMap.layers['base floor'])
    wizard.currentAnimation:draw(wizard.spriteSheet, wizard.x, wizard.y, nil, wizard.scale, wizard.scale)
    cam1:detach()
end