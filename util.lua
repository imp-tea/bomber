util = {}

function util.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function util.rotateTable(t)
    local w = #t[1]
    local h = #t
    local newArray = {}
    for i = 1,w,1 do
        newArray[i] = {}
        for j=1,h,1 do
            newArray[i][j] = t[h-(j-1)][i]
        end
    end
    return newArray
end

function util.randSign()
    if math.random()>0.5 then return -1 end
    return 1
end

function util.truncate(value,precision)
    return math.floor(value/precision)*precision
end

function util.clamp(value,min,max)
    if value>max then return max end
    if value<min then return min end
    return value
end

function util.randomColor(theme)
    local r = math.random()
    local g = math.random()
    local b = math.random()
    local boost = nil
    if theme.bright then
        r = r+0.25
        g = g+0.25
        b = b+0.25
    end
    if theme.dark then
        r = r/2
        g = g/2
        b = b/2
    end
    if theme.red then
        g = g/4
        b = g
        if r<g then r = g+0.25 end
    end
    if theme.green then
        r = r/4
        b = r
        if g<r then g = r+0.25 end
    end
    if theme.blue then
        r = r/4
        g = r
        if b<g then b = g+0.25 end
    end
    if theme.gray then
        local avg = (r + b + g)/3
        r=avg
        g=avg
        b=avg
    end
    return {r,g,b}
end

function util.normalizeAngle(angle)
    while angle > math.pi do
        angle = angle - math.pi
    end
    while angle < math.pi*-1 do
        angle = angle + math.pi
    end
    return angle
end

function util.drawFace(x,y,size)
    local eyeSize = size / 6
    local mouthSize = size / 3
    love.graphics.circle('fill', x-eyeSize*2, y-eyeSize*2, eyeSize)
    love.graphics.circle('fill', x+eyeSize*2, y-eyeSize*2, eyeSize)
    love.graphics.circle('fill', x, y+eyeSize*1.5, mouthSize)
end

function util.tween(period,time,deltas,mode)
    local newValues = {}
    local t = time/period
    for i,delta in ipairs(deltas) do
        if mode == "linear" or mode == nil then
            table.insert(newValues,delta*t)
        end
    end
    return newValues
end

function util.randomNgon (n,r)
    local number = n or math.random(3,10)
    local radius = r or math.random(10,100)
    local points = {}
	for i = 1,number do
		local ang = 2*math.pi * math.random()
        table.insert(points,math.cos(ang)*radius)
        table.insert(points,math.sin(ang)*radius)
	end
    return points
end

 function util.clamp(min,max,value)
     if value>max then return max end
     if value<min then return min end
     return value
 end
