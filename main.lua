if arg[2] == "debug" then
    require("lldebugger").start()
end

-- imports
local gameMap
local cam1

local wizard
local squares -- pixels in one "square" on the game grid
local world
local walls

function love.load()
    local sti = require('lib/sti')
    gameMap = sti('maps/floor example.lua')

    local camera = require('lib/camera')
    cam1 = camera.new(nil, nil, 2)

    local anim8 = require('lib/anim8')
    local wf = require('lib/windfield')

    world = wf.newWorld(0, 0)

    love.graphics.setDefaultFilter('nearest', 'nearest')

    squares = 16

    wizard = {}

    wizard.x = 5 * squares
    wizard.y = 3 * squares
    wizard.speed = 6 * squares
    wizard.scale = 2
    wizard.spriteSheet = love.graphics.newImage('sprites/player/wizard.png')

    wizard.width = 16
    wizard.height = 32

    wizard.grid = anim8.newGrid(
        wizard.width,
        wizard.height,
        wizard.spriteSheet:getWidth(),
        wizard.spriteSheet:getHeight()
    )

    wizard.animation = {}
    wizard.animation.down  = anim8.newAnimation(wizard.grid('1-4', 1), 0.15)
    wizard.animation.left  = anim8.newAnimation(wizard.grid('5-8', 1), 0.15)
    wizard.animation.up    = anim8.newAnimation(wizard.grid('9-12', 1), 0.15)
    wizard.animation.right = anim8.newAnimation(wizard.grid('13-16', 1), 0.15)

    wizard.currentAnimation = wizard.animation.up

    wizard.collider = world:newBSGRectangleCollider(
        100,
        250,
        wizard.width * 2,
        wizard.height, -- would use wizard.height if we wanted it to be the full height; instead, its hat goes above the collider a bit
        wizard.width * 0.5
    )
    wizard.collider:setFixedRotation(true)

    print('loading')
    if (gameMap.layers['obstacles']) then
        walls = {}
        for i, obj in pairs(gameMap.layers['obstacles'].objects) do
            if obj.width > 0 and obj.height > 0 then
                local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                wall:setType('static')
                table.insert(walls, wall)
            end
        end
    else 
        debug.debug()
    end



end

function love.update(dt)
    local vectorX = 0
    local vectorY = 0


    if love.keyboard.isDown("down") then
        vectorY = vectorY + 1
        wizard.currentAnimation = wizard.animation.down
    end
    if love.keyboard.isDown("up") then
        vectorY = vectorY - 1
        wizard.currentAnimation = wizard.animation.up
    end

    if love.keyboard.isDown("right") then
        vectorX = vectorX + 1
        wizard.currentAnimation = wizard.animation.right
    end
    if love.keyboard.isDown("left") then
        vectorX = vectorX - 1
        wizard.currentAnimation = wizard.animation.left
    end
    -- stand still if not moving 
    if vectorX == 0 and vectorY == 0 then
        wizard.currentAnimation:gotoFrame(2)
    -- normalize speed
    elseif vectorX ~= 0 and vectorY ~=0 then
        vectorX = vectorX * .707
        vectorY = vectorY * .707
    end

    wizard.collider:setLinearVelocity(vectorX * wizard.speed, vectorY * wizard.speed)

    wizard.x = wizard.collider:getX()
    wizard.y = wizard.collider:getY() + wizard.height * 0.2 -- adding offset here

    world:update(dt)

    wizard.currentAnimation:update(dt)

    cam1:lookAt(wizard.x, wizard.y)
end


function love.draw() 
    cam1:attach()
    gameMap:drawLayer(
        gameMap.layers['base floor']
    )
    gameMap:drawLayer(
        gameMap.layers['walls and misc boxes']
    )

    wizard.currentAnimation:draw(
        wizard.spriteSheet,
        wizard.x, wizard.y,
        nil, 
        wizard.scale,
        wizard.scale,
        wizard.width / 2,
        wizard.height / 2
    )
    -- world:draw() -- uncomment to view collider outlines

    cam1:detach()
end