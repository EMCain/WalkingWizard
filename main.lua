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
local boxSprite
local boxes
local boxPushSpeed

local function getNearestGridCoords (x, y) 
    local xNumberOfTiles = math.floor(x/squares + 0.5)
    local yNumberOfTiles = math.floor(y/squares + 0.5)
    return { x = xNumberOfTiles * squares, y = yNumberOfTiles * squares }
end

-- TODO: get checkWizardCollision to tell me which side it is hitting 

local function roundToGrid(x)
    if (x > 0) then
        return math.floor(x / squares) * squares
    elseif (x < 0) then
        return math.ceil(x / squares) * squares 
    else 
     return 0
    end
end

function love.load()
    local sti = require('lib/sti')
    gameMap = sti('maps/floor example.lua')

    local camera = require('lib/camera')
    cam1 = camera.new(nil, nil, 2)

    local anim8 = require('lib/anim8')

    world = love.physics.newWorld(0, 0, true)
        --world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    

    love.graphics.setDefaultFilter('nearest', 'nearest')

    squares = 16

    wizard = {}

    -- TODO create a positioning wrapper to handle multiplying by squares

    wizard.speed = 6 * squares
    wizard.scale = 2
    wizard.spriteSheet = love.graphics.newImage('sprites/player/wizard.png')

    -- TODO see about replacing these with getters on wizard.shape
    wizard.width = 16
    wizard.height = 20

    -- TODO roll my own animation renderer with quads and this tutorial https://sheepolution.com/learn/book/17
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

    wizard.body = love.physics.newBody(world, 5*squares, 3*squares, "dynamic")
    wizard.body:setFixedRotation(true)
    wizard.shape = love.physics.newRectangleShape(wizard.width, wizard.height)
    wizard.fixture = love.physics.newFixture(wizard.body, wizard.shape)
    wizard.fixture:setUserData("wizard.fixture")
    wizard.fixture:setRestitution(0)

    print('loading')
    if (gameMap.layers['walls - objects']) then
        walls = {}
        for i, obj in pairs(gameMap.layers['walls - objects'].objects) do
            if obj.width > 0 and obj.height > 0 then
                local wall = {}
                wall.body = love.physics.newBody(
                    world, 
                    obj.x + obj.width / 2,
                    obj.y + obj.height / 2,
                    "static")

                wall.shape = love.physics.newRectangleShape(obj.width, obj.height)
                wall.fixture = love.physics.newFixture(wall.body, wall.shape)

                table.insert(walls, wall)
            end
        end
    else 
        debug.debug()
    end

    boxSprite = {}
    boxPushSpeed = 0.5 * squares
    -- If I want to open boxes this can be reworked.
    boxSprite.closed = love.graphics.newImage('sprites/objects/boxAnimation1-Sheet-byandrox-closed.png')

    if(gameMap.layers['boxes - objects']) then
        boxes = {}
        for i, obj in pairs(gameMap.layers['boxes - objects'].objects) do
            local box = {}
            local gridCoords = getNearestGridCoords(obj.x, obj.y)
            
            box.body = love.physics.newBody(world, gridCoords.x, gridCoords.y, "kinematic")
            box.shape = love.physics.newRectangleShape(squares, squares)


            box.sprite = boxSprite.closed
            box.x = gridCoords.x
            box.y = gridCoords.y
            box.destination = {x=gridCoords.x, y=gridCoords.y}
            box.oldPosition = {x=gridCoords.x, y=gridCoords.y}
            table.insert(boxes, box)
        end
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

    wizard.body:setLinearVelocity(vectorX * wizard.speed, vectorY * wizard.speed)

    world:update(dt)

    wizard.currentAnimation:update(dt)
    
    cam1:lookAt(wizard.body:getX(), wizard.body:getY())

    --  TODO I can probably keep some of the logic around destination here, though 
    -- I may want to move it to one of the callback methods for world.setCallbacks
    -- -- box collisions and movement
    -- for i, box in pairs (boxes) do 
    --     local xDistanceToDestination = box.x - box.destination.x
    --     local yDistanceToDestination = box.y - box.destination.y
    --     -- if (xDistanceToDestination > squares * 1.5) then break 
    --     -- end
    --     -- print ('xDistanceToDestination', xDistanceToDestination)
    --                 --print(box.x, xDistanceToDestination, box.destination.x)

    --     if xDistanceToDestination > 0 and xDistanceToDestination <= squares * 2 then
    --         box.x = box.x + dt * boxPushSpeed
    --     elseif xDistanceToDestination < 0  and xDistanceToDestination >= squares * 2  then
    --         box.x = box.x - dt * boxPushSpeed
    --     elseif yDistanceToDestination > 0 and yDistanceToDestination <= squares * 2 then
    --         box.y =  box.y + dt * boxPushSpeed
    --     elseif yDistanceToDestination < 0 and yDistanceToDestination >= squares * 2 then
    --         box.y = box.y - dt * boxPushSpeed
    --     else
    --         -- if (math.abs(box.x - box.oldPosition.x) > squares or math.abs(box.y - box.oldPosition.y) > squares) then 
    --         --     break
    --         -- end
    --         -- box.oldPosition.x = box.x
    --         -- print(collisionSides.x, box.oldPosition.x, box.destination.x, box.x - box.oldPosition.x)
    --         -- if (collisionSides.x ~= 0 and math.abs(box.x - box.oldPosition.x) < squares) then 
    --         --     box.oldPosition.x = box.x
    --         if (collisionSides.x ~= 0) then
    --             box.destination.x = roundToGrid(box.x) + collisionSides.x * squares
    --         elseif (collisionSides.y ~=0) then 
    --             box.destination.y = roundToGrid(box.y) + collisionSides.y * squares
    --         end
    --         print('x', collisionSides.x, 'y', collisionSides.y)
    --         --end
    --         -- local newDestinationY = box.destination.y + collisionSides.y * squares 
    --         -- local distToNewDestY = math.abs(newDestinationY - box.oldPosition.y)
    --         -- print('distToNewDestX', distToNewDestX)
    --         -- if distToNewDestX =< 0 then 
                
    --         -- else if distToNewDestX <= squares then 
    --         --     box.destination.x = newDestinationX
    
    --         -- else if distToNewDestY > 0 and distToNewDestY <= squares then box.destination.y = newDestinationY        
    --     end
    -- end 
end


function love.draw() 
    cam1:attach()
    gameMap:drawLayer(
        gameMap.layers['base floor']
    )
    gameMap:drawLayer(
        gameMap.layers['walls - tiles']
    )
    -- don't render the "boxes - tiles - hidden" layer, it is just for visual reference in Tiled
    
    -- TODO replace this with quads - see https://sheepolution.com/learn/book/17
    wizard.currentAnimation:draw(
        wizard.spriteSheet,
        wizard.body:getX() + wizard.width / 2,
        wizard.body:getY() + wizard.height / 2,
        nil, 
        1, 
        1,
        wizard.width,
        wizard.height
    )

    -- draaw body for debugging 
    love.graphics.polygon("line", wizard.body:getWorldPoints(wizard.shape:getPoints()))
    
    for i, obj in pairs (boxes) do 
        love.graphics.draw(obj.sprite, obj.x, obj.y)
    end 

    cam1:detach()
end