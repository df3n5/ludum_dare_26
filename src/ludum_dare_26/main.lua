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

Player = Fill:extend {
    x = 0, 
    y = 0, 
    width = 32, 
    height = 48,
    acceleration = { y = 600 },
    fill = {0, 0, 0},
    moveMode = "normal",
    --moveMode = "onlyJump",
    --conveyorMode = "conveyorLeft",
    conveyorMode = "normal",

    onUpdate = function (self)
        self.velocity.x = 0
        if self.conveyorMode == "conveyorLeft" and (self.canJump) then
            self.velocity.x = -100
        end
        if self.conveyorMode == "conveyorRight" and (self.canJump) then
            self.velocity.x = 100
        end
        if self.moveMode=="normal" or (self.moveMode=="onlyJump" and not self.canJump) then
            if the.keys:pressed('left') then
                self.velocity.x = self.velocity.x - 150
            elseif the.keys:pressed('right') then
                self.velocity.x = self.velocity.x + 150
            else
                if self.conveyorMode == "none" then
                    self.velocity.x = 0
                end
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
            self:reset()
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
    reset = function(self)
        self.x = 0
        self.y = 0
    end
}

Platform = Fill:extend {
    x = 0, 
    y = 0, 
    width = 128,
    height = 32,
    fill = {0, 0, 0},
    platformType = "normal",
    --platformType = "breakable",
    isDying = false,
    onUpdate = function (self, elapsed)
        if self.isDying then
            self.timeToDie = self.timeToDie - elapsed
            if self.timeToDie <= 0 then
                self:die()
            end
        end
    end,
    onCollide = function (self, other)
        if(other.velocity.y > 0) then
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

Spike = Tile:extend {
    x = 0, 
    y = 0, 
    width = 32,
    height = 32,
    image = "media/spike.png",
    onCollide = function (self, other)
        other:reset()
    end
}

the.app = App:new {
    loadLevel = function(self, level) 
        if level == 1 then
            -- TODO: Transition to next scene
            self.background = Fill:new{x=0, y=0, width=the.app.width, height=the.app.height}
            self:add(self.background)
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
                    self.level = 1
                    self:loadLevel(self.level)
                end
            end
        elseif self.state == "level" then
            self.platforms:collide(self.player)
            self.topSpikes:collide(self.player)
            self.bottomSpikes:collide(self.player)
            for k, spike in pairs(self.topSpikes.sprites) do
                -- move down
                if roughlyEqual(spike.x, self.player.x, 2.0) then
                    spike.velocity.y = 400
                end
            end            
        end
    end
}
