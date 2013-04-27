STRICT = true
DEBUG = true

require 'zoetrope'

function roughlyEqual(a, b, tolerance)
    if ((a-b) < tolerance) and ((a-b) > -tolerance) then
        return true
    else
        return false
    end
end

Title = Tile:extend {
    image = 'media/title.png',
}

resetNeeded = false

function saveOrigPos(obj)
    obj.origX = obj.x
    obj.origY = obj.y
    obj.origVel = obj.velocity
    obj.origAcceleration = obj.acceleration
end

function reset(obj)
    obj.x = obj.origX
    obj.y = obj.origY
    obj.velocity = obj.origVel
    obj.acceleration = obj.origAcceleration
end

ResetableFill = Fill:extend {
    onNew = function(self)
        saveOrigPos(self)
    end,
    reset = reset
}

ResetableTile = Tile:extend {
    onNew = function(self)
        saveOrigPos(self)
    end,
    reset = reset
}

Player = ResetableFill:extend {
    x = 0, 
    y = 0, 
    width = 16, 
    height = 24,
    acceleration = { y = 600 },
    fill = {100, 100, 100},
    moveMode = "normal",
    --moveMode = "onlyJump",
    --conveyorMode = "conveyorLeft",
    --moveMode = "topdown",
    conveyorMode = "normal",
    canFire = true,
    direction = 'right',
    speed = 200,

    onUpdate = function (self)
        self.velocity.x = 0
        if self.conveyorMode == "conveyorLeft" and (self.canJump) then
            self.velocity.x = -100
        end
        if self.conveyorMode == "conveyorRight" and (self.canJump) then
            self.velocity.x = 100
        end
        if self.moveMode=="topdown" or self.moveMode=="normal" or (self.moveMode=="onlyJump" and not self.canJump) then
            if the.keys:pressed('left') then
                self.velocity.x = self.velocity.x - self.speed
                self.direction = 'left'
            elseif the.keys:pressed('right') then
                self.velocity.x = self.velocity.x + self.speed
                self.direction = 'right'
            else
                if self.conveyorMode == "none" then
                    self.velocity.x = 0
                end
            end
        end

        if self.moveMode == "topdown" then
            if the.keys:pressed('up') then
                self.velocity.y = -self.speed
            elseif the.keys:pressed('down') then
                self.velocity.y = self.speed
            else
                self.velocity.y = 0
            end
        end

        --Jump logic
        if the.keys:justPressed(' ') and self.canJump then
            if roughlyEqual(self.y, self.lastpos.y, 0.2) then
                playSound('media/jump.wav', 1.0)
                self.velocity.y = -500
                self.canJump = false
            end
        end

        -- Reset if you go off screen
        if self.y > the.app.height then
            resetNeeded = true
        end
        self.lastpos = {x=self.x, y=self.y}
    end,
 
    onCollide = function (self)
        if self.velocity.y > 0 then
            self.velocity.x = 0
            self.velocity.y = 0
            self.canJump = true
        end
    end,
}

Platform = ResetableFill:extend {
    x = 0, 
    y = 0, 
    width = 128,
    height = 32,
    fill = {0, 0, 0},
    platformType = "normal",
    squashMode = "vertical",
    --platformType = "breakable",
    isDying = false,
    jumpable = false,
    movementToCentreSpeed = 80,

    moveTowardsCentre = function(self)
        if self.squashMode=="vertical" then
            if(self.y > the.app.height/2) then
                self.velocity.y = -self.movementToCentreSpeed
            else
                self.velocity.y = self.movementToCentreSpeed
            end
        elseif self.squashMode=="horizontal" then
            if(self.x > the.app.width/2) then
                self.velocity.x = -self.movementToCentreSpeed
            else
                self.velocity.x = self.movementToCentreSpeed
            end
        end
    end,

    onUpdate = function (self, elapsed)
        if self.isDying then
            self.timeToDie = self.timeToDie - elapsed
            if self.timeToDie <= 0 then
                self:die()
            end
        end
    end,

    onCollide = function (self, other)
        if other:instanceOf(Platform) then
            print("2 platforms colliding")
            self:die()
            other:die()
        end
        if (other.velocity.y > 0) or (not self.jumpable) then
            if not self.isDying then
                if self.platformType == "breakable" then
                    self.timeToDie = 0.5
                    self.isDying = true
                end
            end
            self:displace(other)
        end
    end
}

Spike = ResetableTile:extend {
    x = 0, 
    y = 0, 
    width = 32,
    height = 32,
    image = "media/spike.png",

    onCollide = function (self, other)
        resetNeeded = true
    end
}

Boss = ResetableTile:extend {
    x = 0, 
    y = 0, 
    width = 128,
    height = 128,
    image = "media/bigSpike.png",
    health = 20,
    fill = {150, 150, 150},
    
    onCollide = function (self, other)
        if other:instanceOf(Player) then
            resetNeeded = true
        end
    end,

    onUpdate = function (self)
        if self.player.x < self.x then
            self.velocity.x = -10
        else
            self.velocity.x = 10
        end
    end
}

Bullet = ResetableFill:extend {
    x = 0, 
    y = 0, 
    width = 8,
    height = 4,
    fill = {0, 0, 0},
    onCollide = function (self, other)
        other.health = other.health - 10
        if other.health <= 0 then
            other:die()
        end
        self:die()
    end
}

Door = ResetableFill:extend {
    x = 0, 
    y = 0, 
    width = 32,
    height = 48,
    fill = {0, 255, 12},
    border = {0, 0, 0}
}

the.app = App:new {
    loadLevel = function(self, level) 
        self.background = Fill:new{x=0, y=0, width=the.app.width, height=the.app.height}
        self:add(self.background)
        if level == 1 then
            -- TODO: Transition to next scene
            self.player = Player:new{}
            self:add(self.player) 
            self.platforms = Group:new()
            self.platforms:add(Platform:new{x=0,y=400 })
            self.platforms:add(Platform:new{x=250,y=400 })
            self.platforms:add(Platform:new{x=400,y=500, width=200})
            self.platforms:add(Platform:new{x=600,y=400, width=100})
            self.platforms:add(Platform:new{x=700,y=200, width=100})
            self.platforms:add(Platform:new{x=100,y=100, width=600})
            self:add(self.platforms)
            self.topSpikes = Group:new()
            startX = 100
            n_spikes = 15
            --top spikes
            for i=1, n_spikes do
                self.topSpikes:add(Spike:new{x=startX + (i-1)*Spike.width})
            end
            self:add(self.topSpikes)

            self.bottomSpikes = Group:new()
            startX = 100
            startY = the.app.height - Spike.height
            n_spikes = 15
            --bottom spikes
            for i=1, n_spikes do
                self.bottomSpikes:add(Spike:new{x=startX + (i-1)*Spike.width, y=startY, flipY = true})
            end
            self:add(self.bottomSpikes)
        elseif level == 2 then
            self.player = Player:new{x=100, y=200}
            self:add(self.player) 
            self.platforms = Group:new()
            self.platforms:add(Platform:new{x=100,y=300, width=600})
            self:add(self.platforms)
            self.boss = Boss:new{x=the.app.width/2, y=300 - Boss.height, player=self.player}
            self:add(self.boss) 
            self.bullets = Group:new()
            self:add(self.bullets)
        elseif level == 3 then
            self.platforms = Group:new()
            self.platforms:add(Platform:new{x=100,y=100,width=600})
            self.platforms:add(Platform:new{x=200,y=200,width=600})
            self.platforms:add(Platform:new{x=150,y=300,width=550})
            self.platforms:add(Platform:new{x=400,y=450,width=400})
            self:add(self.platforms)
            self.door = Door:new{x=400,y=450-Door.height}
            self:add(self.door)

            self.sideSpikes = Group:new()
            n_spikes = (600 / 32)+1
            print(n_spikes)
            for i=1, n_spikes do
                spike = Spike:new{x=0, y=(i-1)*Spike.height, rotation=math.rad(-90)}
                spike.velocity.x = 10
                self.sideSpikes:add(spike)
            end
            self:add(self.sideSpikes)

            self.player = Player:new{x=100, y=0}
            self:add(self.player) 
        elseif level == 4 then
            self.platforms = Group:new()
            self.platforms:add(Platform:new{x=100,y=100,width=700, height=16, squashMode="vertical"})
            self.platforms:add(Platform:new{x=100,y=500,width=700, height=16, squashMode="vertical"})
            self.platforms:add(Platform:new{x=-200,y=100,width=100, width=16, height = the.app.height-100, squashMode="horizontal"})
            self.platforms:add(Platform:new{x=the.app.width+200,y=100,width=16, height = the.app.height-100, squashMode="horizontal"})
            self:add(self.platforms)

            self.player = Player:new{x=the.app.width/2, y=the.app.height/2, acceleration={x=0, y=0}, moveMode="topdown" }
            self:add(self.player) 
        end
    end,
    onRun = function (self)
        self.title = Title:new{}
        self:add(self.title)
        self.started = false
        self.state = "title"
    end,
    onUpdate = function (self, elapsed)
        if the.keys:pressed('escape') then
            self.quit()
        end
        if self.state == "title" then
            if the.keys:justPressed(' ') then
                if not self.started then
                    self.started = true
                    playSound('media/title.wav')
                    self:remove(self.title)
                    self.state = "level"
                    --self.level = 1
                    --self.level = 2
                    --self.level = 3
                    self.level = 4
                    self:loadLevel(self.level)
                end
            end
        elseif self.state == "level" then
            if self.level == 1 then
                self.platforms:collide(self.player)
                self.topSpikes:collide(self.player)
                self.bottomSpikes:collide(self.player)
                for k, spike in pairs(self.topSpikes.sprites) do
                    -- move down
                    if roughlyEqual(spike.x, self.player.x, 2.0) then
                        spike.velocity.y = 400
                    end
                end            
            elseif self.level == 2 then
                self.platforms:collide(self.player)
                self.boss:collide(self.player)
                self.bullets:collide(self.boss)
 
                if the.keys:justPressed('a') and self.player.canFire then
                    self:fire(self.player)
                end               
            elseif self.level == 3 then
                self.platforms:collide(self.player)
                self.sideSpikes:collide(self.player)
                if(resetNeeded == true) then
                    reset(self.player)
                    for k, spike in pairs(self.sideSpikes.sprites) do
                        reset(spike)
                    end
                    resetNeeded = false
                end
                x, y = self.player:overlap(self.door.x, self.door.y, self.door.width, self.door.height)
                if x>0 or y>0 then
                    if the.keys:justPressed('a') then
                        playSound('media/levelFinish.wav')
                    end
                end
            elseif self.level == 4 then
                --check to see if sqashed by 2 platforms
                nCollisions = 0
                for k, platform in pairs(self.platforms.sprites) do
                    if platform.active then
                        x, y = self.player:overlap(platform.x, platform.y, platform.width, platform.height)
                        if x>0 or y>0 then
                            nCollisions = nCollisions + 1
                        end
                    end
                end
                if nCollisions > 1 then
                    resetNeeded = true
                end
                self.platforms:collide(self.player)
                self.platforms:collide(self.platforms)
                for k, platform in pairs(self.platforms.sprites) do
                    platform:moveTowardsCentre()
                end
                if(resetNeeded == true) then
                    self:loadLevel(self.level)
                    resetNeeded = false
                end
            end
        end
    end,
    fire = function(self, player)
        bulletSpeed = 700
        bulletVel = bulletSpeed
        x = self.player.x + self.player.width
        if player.direction == "left" then
            bulletVel = -bulletVel
            x = self.player.x - Bullet.width
        end
        self.bullets:add(Bullet:new{x=x, y=player.y+10, velocity={x=bulletVel} })
    end
}
