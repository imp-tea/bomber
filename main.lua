local class = require 'middleclass'
require 'Terrain'
require 'Obstacle'
require 'Entity'
require 'Camera'
require 'Player'
require 'Bomb'
require 'util'

math.randomseed(os.time())

function love.load()
    WIDTH, HEIGHT = love.window.getDesktopDimensions(1)
    HEIGHT = HEIGHT - 100
    WIDTH = WIDTH - 100
    World = love.physics.newWorld(0,1000,true)
    window = love.window.setMode(WIDTH,HEIGHT,{msaa = 2})
    love.graphics.setBackgroundColor(util.randomColor({dark=true, red=true}))
    theme = {red=true,bright=true}
    ground = Terrain:new(World,WIDTH/2,HEIGHT-50,{width = WIDTH, height = 100, color = util.randomColor(theme)})
    leftWall = Terrain:new(World,-10,HEIGHT/2,{width = 20, height = HEIGHT, userData = {}, restitution = 0.5})
    rightWall = Terrain:new(World, WIDTH+10,HEIGHT/2,{width = 20, height = HEIGHT, userData = {}, restitution = 0.5})
    ceiling = Terrain:new(World,WIDTH/2,-25,{width = WIDTH, height = 50, userData = {}, restitution = 0.5})
    trampolineL = Terrain:new(World,80,HEIGHT-180,{restitution = 2, type = 'polygon', points = {-80,-80,-80,80,80,80}, color = util.randomColor(theme)})
    trampolineL = Terrain:new(World,WIDTH-80,HEIGHT-180,{restitution = 2, type = 'polygon', points = {80,-80,80,80,-80,80}, color = util.randomColor(theme)})

    player = Player:new(World,WIDTH/2,HEIGHT/3,{group = 1, fixedRotation = true, ungroundedMultiplier = 0.2, height = 50, width = 25, color = util.randomColor(theme), shape='pill', })
    
    platform = Obstacle:new(World, WIDTH/2+100, HEIGHT-150, {
        width = 150,
        height = 30,
        color = util.randomColor(theme),
        friction = 0.5,
        path = {
            {2,-200,0,0,"eased"},
            {2,0,-400,0,"eased"},
            {2,200,0,0,"eased"},
            {2,0,400,0,"eased"},
        }
    })

    wheelA = Obstacle:new(World, WIDTH/2, 325, {
        width = 220,
        height = 20,
        color = util.randomColor(theme),
        path = {
            {1.8,0,0,0},
            {0.2,0,0,math.pi/2,"eased"},
        }
    })
    wheelB = Obstacle:new(World, WIDTH/2, 325, {
        width = 20,
        height = 220,
        color = util.randomColor(theme),
        path = {
            {1.8,0,0,0},
            {0.2,0,0,math.pi/2,"eased"},
        }
    })

    camera = Camera:new()
end

function love.update(dt)
    player:update(dt)
    for k,entity in pairs(Entities) do
        entity:update()
    end
    for k,obstacle in pairs(Obstacles) do
        obstacle:update()
    end
    for k, bomb in pairs(Bombs) do
        bomb:update(dt)
    end
    camera:update()
    World:update(dt)

end

function love.draw()
    camera:set()
    love.graphics.setLineWidth(2)
    for k,entity in pairs(Entities) do
        entity:draw()
    end
    for k,obstacle in pairs(Obstacles) do
        obstacle:draw()
    end
    for k,terrain in pairs(Terrains) do
        terrain:draw()
    end
    for k, bomb in pairs(Bombs) do
        bomb:draw()
    end
    camera:unset()

    --love.graphics.print("X: "..math.floor(love.mouse.getX()).."  Y= "..math.floor(love.mouse.getY()), 50, 50)
end

function love.keypressed(key, scancode, isrepeat)

end


function love.mousepressed(x, y, button, isTouch)
    x=x+camera.x
    y=y+camera.y
    local bomb = Bomb(World, x, y, {vx = math.random(50, 1000), radius = math.random(3, 10)})
end

function love.mousereleased(x, y, button, isTouch)
    x=x+camera.x
    y=y+camera.y
end