
function ObjectNew(o, self)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

Sprite = {image="", 
    pos={x=0, y=0},
    rot=0,
    scale={x=1, y=1},
    halfDims={w=0, h=0},
    currentLeg=1}

function Sprite:new(o)
    return ObjectNew(o, self)
end

function Sprite:init()
    self.sprite = love.graphics.newImage(self.image)
    self.halfDims.w = self.sprite:getWidth() / 2
    self.halfDims.h = self.sprite:getHeight() / 2
    self.centrePos = {}
    self.centrePos.x = self.pos.x + self.halfDims.w
    self.centrePos.y = self.pos.y + self.halfDims.h
end

function Sprite:draw()
    love.graphics.draw(self.sprite, 
        self.pos.x, 
        self.pos.y, 
        self.rot, 
        self.scale.x,
        self.scale.y, 
        self.halfDims.w, 
        self.halfDims.h)
end

function Sprite:setPos(pos)
    self.pos = pos
    self.centrePos.x = self.pos.x + self.halfDims.w
    self.centrePos.y = self.pos.y + self.halfDims.h
end
