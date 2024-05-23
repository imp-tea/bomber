local class = require 'middleclass'
require 'Terrain'
require 'Obstacle'
require 'Entity'
require 'Camera'
require 'Chain'
require 'util'

math.randomseed(os.time())

function love.load()
    WIDTH, HEIGHT = love.window.getDesktopDimensions(1)
    HEIGHT = HEIGHT - 60
    World = love.physics.newWorld(0,1000,true)
    window = love.window.setMode(WIDTH,HEIGHT,{msaa = 2})
    love.graphics.setBackgroundColor(util.randomColor({dark=true, red=true}))
    theme = {red=true,bright=true}
    player = Entity:new(World,WIDTH/2,HEIGHT/3,{group = 1, bobble = true, fixedRotation = false,angularDamping = 3, ungroundedMultiplier = 0.2, height = 50, width = 25, color = util.randomColor(theme), headSize = 0.8})
    dummy = Entity:new(World,WIDTH/4,HEIGHT/2,{headSize = 0.9,carryable = true,userData = {jumpable=true,carryable=true},bobble = true, group = 1, color = util.randomColor(theme), angularDamping = 1,width=50,height=100,density=1,restitution=0.5,vx=(math.random()-math.random())*5})
    dummy.moveForce = dummy.moveForce / 3
    ground = Terrain:new(World,WIDTH/2,HEIGHT-50,{width = WIDTH, height = 100, color = util.randomColor(theme)})
    leftWall = Terrain:new(World,-10,HEIGHT/2,{width = 20, height = HEIGHT, userData = {}, restitution = 0.5})
    rightWall = Terrain:new(World, WIDTH+10,HEIGHT/2,{width = 20, height = HEIGHT, userData = {}, restitution = 0.5})
    ceiling = Terrain:new(World,WIDTH/2,-25,{width = WIDTH, height = 50, userData = {}, restitution = 0.5})
    trampolineL = Terrain:new(World,80,HEIGHT-180,{restitution = 2, type = 'polygon', points = {-80,-80,-80,80,80,80}, color = util.randomColor(theme)})
    trampolineL = Terrain:new(World,WIDTH-80,HEIGHT-180,{restitution = 2, type = 'polygon', points = {80,-80,80,80,-80,80}, color = util.randomColor(theme)})
    grabbedBody = nil
    mouseJoint = nil

    fireball = Entity:new(World,WIDTH*0.75,HEIGHT/2,
    {
        userData = {jumpable=true},
        group = 1,
        color = {1,1,0.5,1},
        angularDamping = 1,
        radius=20,
        density=2,
        shape='circle',
        restitution=1.1
    })

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

    local p = {}
    for i=1,math.random(2,10) do
        local step = {
            math.random()*3,
            math.random()*200*util.randSign(),
            math.random()*200*util.randSign(),
            math.random()*2*math.pi*util.randSign(),
            "eased"
        }
        table.insert(p,step)
    end
    local sumDX = 0
    local sumDY = 0
    local sumDA = 0
    for i=1,#p do
        sumDX = sumDX + p[i][2]
        sumDY = sumDY + p[i][3]
        sumDA = sumDA + p[i][4]
    end
    table.insert(p,{2,sumDX*-1,sumDY*-1,sumDA*-1,"eased"})
    randomPlatform = Obstacle:new(World, WIDTH/2, HEIGHT/2, {
        type = "polygon",
        points = util.randomNgon(math.random(3,8),100),
        color = util.randomColor(theme),
        friction = math.random(),
        restitution = math.random(),
        path = p
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

    box = Entity:new(World,WIDTH/2,150, {shape = 'rectangle',width=500,height=10,color=util.randomColor(theme)})

    chain = Chain:new(World,{x=WIDTH/2-200,y=0},{x=WIDTH/2-200,y=145},{anchors={{'coordinates'},{'body',box.body}},group=0, linkNumber = 15})
    chain2 = Chain:new(World,{x=WIDTH/2+200,y=0},{x=WIDTH/2+200,y=145},{anchors={{'coordinates'},{'body',box.body}},group=0, linkNumber = 15})

    camera = Camera:new()
    camera.target = player
end

function love.update(dt)
    for k,entity in pairs(Entities) do
        entity:update()
    end
    for k,obstacle in pairs(Obstacles) do
        obstacle:update()
    end

    if love.keyboard.isDown("d") then player:move("R") end
    if love.keyboard.isDown("a") then player:move("L") end
    if love.keyboard.isDown("w") then player:jump() end

    if player.x < dummy.x then dummy:move("L") end
    if player.x > dummy.x then dummy:move("R") end
    if player.y < dummy.y-200 then dummy:jump() end
    if grabbedBody ~= nil then
        local mx = love.mouse.getX() + camera.x
        local my = love.mouse.getY() + camera.y
        mouseJoint:setTarget(mx,my)
    end
    local vx,vy = fireball.body:getLinearVelocity()
    local v = math.sqrt(vx*vx + vy*vy)
    fireball.fixtures[1]:setRestitution(util.clamp(0.5,1.5,1000/v))

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
    for k,chain in pairs(Chains) do
        chain:draw()
    end
    for k,terrain in pairs(Terrains) do
        terrain:draw()
    end
    camera:unset()

    love.graphics.print("X: "..math.floor(love.mouse.getX()).."  Y= "..math.floor(love.mouse.getY()), 50, 50)
end

function love.keypressed(key, scancode, isrepeat)

end


function love.mousepressed(x, y, button, isTouch)
    x=x+camera.x
    y=y+camera.y
    if button == 1 then
        local bodies = World:getBodies()
        for i,body in pairs(bodies) do
            if body:getType() == 'dynamic' then
                local fixtures = body:getFixtures()
                for j,fixture in pairs(fixtures) do
                    if fixture:testPoint(x,y) then
                        grabbedBody = body
                        break
                    end
                end
                if grabbedBody ~= nil then break end
            end
        end
        if grabbedBody ~= nil then
            mouseJoint = love.physics.newMouseJoint(grabbedBody, x, y)
        end
    end
    if button == 2 then
        explode(World,x,y,10)
    end
end

function love.mousereleased(x, y, button, isTouch)
    if button == 1 then
        if grabbedBody ~= nil then
            grabbedBody = nil
            mouseJoint:destroy()
        end
    end
end

function explode(world,x,y,strength)
    local maxDistance = strength*50
    local bodies = World:getBodies()
    for i,body in pairs(bodies) do
        if body:getType() == 'dynamic' then
            local dx = body:getX() - x
            local dy = body:getY() - y
            local angle = math.atan2(dy,dx)
            local d = math.sqrt(dx*dx + dy*dy)
            if d < maxDistance then
                if d < 20 then d = 20 end
                local impulse = 100*maxDistance / d
                body:applyLinearImpulse(math.cos(angle)*impulse, math.sin(angle)*impulse)
            end
        end
    end
end
