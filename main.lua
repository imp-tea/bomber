local class = require 'middleclass'
require 'Terrain'
require 'Obstacle'
require 'Entity'
require 'Camera'
require 'Player'
require 'Bomb'
require 'Cannon'
require 'util'

math.randomseed(os.time())

Updateables = {}
Drawables = {}

function love.load()
    WIDTH, HEIGHT = love.window.getDesktopDimensions(1)
    HEIGHT = HEIGHT - 100
    WIDTH = WIDTH - 100
    World = love.physics.newWorld(0,1500,true)
    window = love.window.setMode(WIDTH,HEIGHT,{msaa = 2})
    love.graphics.setDefaultFilter( "nearest","nearest")
    love.graphics.setBackgroundColor(util.randomColor({dark=true}))
    theme = {gray=true, bright=true}
    ground = Terrain:new(World,WIDTH/2,HEIGHT-50,{width = WIDTH, height = 100, color = util.randomColor(theme)})
    leftWall = Terrain:new(World,-10,HEIGHT/2,{width = 20, height = HEIGHT, userData = {}, restitution = 0.5})
    rightWall = Terrain:new(World, WIDTH+10,HEIGHT/2,{width = 20, height = HEIGHT, userData = {}, restitution = 0.5})
    ceiling = Terrain:new(World,WIDTH/2,-25,{width = WIDTH, height = 50, userData = {}, restitution = 0.5})
    trampolineL = Terrain:new(World,80,HEIGHT-180,{restitution = 2, type = 'polygon', points = {-80,-80,-80,80,80,80}, color = util.randomColor(theme)})
    trampolineL = Terrain:new(World,WIDTH-80,HEIGHT-180,{restitution = 2, type = 'polygon', points = {80,-80,80,80,-80,80}, color = util.randomColor(theme)})

    player = Player:new(World,WIDTH/2,HEIGHT/3,{group = 1, fixedRotation = true, ungroundedMultiplier = 0.2, height = 64, width = 40, color = util.randomColor(theme), shape='pill'})
    cannon = Cannon:new(World, WIDTH/3, 400, {color = util.randomColor(theme), target = player})

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
    for k,updateable in pairs(Updateables) do
        updateable:update(dt)
    end
    camera:update()
    World:update(dt)

end

function love.draw()
    camera:set()
    love.graphics.setLineWidth(2)
    for k, drawable in pairs(Drawables) do
        drawable:draw()
    end
    camera:unset()
end

function love.keypressed(key, scancode, isrepeat)

end


function love.mousepressed(x, y, button, isTouch)
    x=x+camera.x
    y=y+camera.y

    player.charging = true
end

function love.mousereleased(x, y, button, isTouch)
    x=x+camera.x
    y=y+camera.y
    if player.charging then
        player:shoot()
        player.charge = player.minimumCharge
        player.charging = false
    end
end

function love.wheelmoved(x, y)
    camera:zoom(y)
end