STRICT = false
DEBUG = false

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
storyMode = false
soundLevel = 0.5
spikeFallingSpeed = 200
sideSpikeSpeed = 10

function playSfx(path)
    return playSound(path, soundLevel, "short")
end

function playMusic(path)
    music = sound(path, "long")
    music:setLooping(true)
    music:play()
    return music
end

function saveOrigPos(obj)
    obj.origX = obj.x
    obj.origY = obj.y
    obj.origVel = {}
    obj.origVel.x = obj.velocity.x
    obj.origVel.y = obj.velocity.y
    obj.origAcceleration = {}
    obj.origAcceleration.x = obj.acceleration.x
    obj.origAcceleration.y = obj.acceleration.y
    if not (obj.health==nil) then
        obj.origHealth = obj.health
    end
end

function reset(obj)
    obj.x = obj.origX
    obj.y = obj.origY
    obj.velocity.x = obj.origVel.x
    obj.velocity.y = obj.origVel.y
    obj.acceleration.x = obj.origAcceleration.x
    obj.acceleration.y = obj.origAcceleration.y
    if not (obj.health==nil) then
        obj.health = obj.origHealth
    end
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
    direction = 'right',
    speed = 200,
    isOverDoor = false,
    hasJumpPowerUp = false,
    hasGunPowerUp = false,
    isFinished = false,
    lastpos = {x=0, y=0},

    onUpdate = function (self)
        self.isOverDoor = false -- Should be set by door class to true
        if(not storyMode) then
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
                elseif the.keys:pressed('right') then
                    self.velocity.x = self.velocity.x + self.speed
                else
                    if self.conveyorMode == "none" then
                        self.velocity.x = 0
                    end
                end
            end

            if the.keys:pressed('left') then
                self.direction = 'left'
            elseif the.keys:pressed('right') then
                self.direction = 'right'
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
            if the.keys:pressed(' ') and self.canJump then
                if roughlyEqual(self.y, self.lastpos.y, 0.2) then
                    if(self.hasJumpPowerUp) then
                        playSfx('media/jumpbig.ogg')
                        self.velocity.y = -500
                    else
                        playSfx('media/jump.ogg')
                        self.velocity.y = -200
                    end
                    self.canJump = false
                end
            end

            -- Reset if you go off screen
            if self.y > the.app.height then
                resetNeeded = true
            end
            self.lastpos = {x=self.x, y=self.y}
        end
    end,
 
    onCollide = function (self, other)
        if other:instanceOf(Platform) then
            if self.velocity.y > 0 then
                self.velocity.x = 0
                self.velocity.y = 0
                self.canJump = true
            end
        end
    end,
}

Platform = ResetableFill:extend {
    x = 0, 
    y = 0, 
    width = 128,
    height = 16,
    fill = {0, 0, 0},
    platformType = "normal",
    squashMode = "none",
    --platformType = "breakable",
    isDying = false,
    jumpable = false,
    movementToCentreSpeed = 120,

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
    speed = 60,
    
    onCollide = function (self, other)
        if other:instanceOf(Player) then
            resetNeeded = true
        end
    end,

    onUpdate = function (self, delta)
        if self.player.x < (self.x + (self.width/2)) then
            self.velocity.x = -self.speed
        else
            self.velocity.x = self.speed
        end
        if not (self.timeToNormal == nil) then
            self.timeToNormal = self.timeToNormal - delta
            if(self.timeToNormal < 0) then
                self.timeToNormal = nil
                self.tint = {1,1,1}
            end
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
        other.health = other.health - 1
        if other.health <= 0 then
            other:die()
            other.dead=true
            playSfx("media/explosion.ogg")
        end
        other.tint = {0.5,0.5,0.5}
        other.timeToNormal = 0.1
        playSfx("media/blip.ogg")
        self:die()
    end
}

Door = ResetableFill:extend {
    x = 0, 
    y = 0, 
    width = 32,
    height = 48,
    fill = {20, 255, 20},
    border = {0, 0, 0},
    onCollide = function (self, other)
        other.isOverDoor = true
    end
}

T = ResetableTile:extend {
    x = 0, 
    y = 0, 
    width = 32,
    height = 32,
    image = "media/t.png",
    onCollide = function (self, other)
        other.isFinished = true
    end
}


JumpPowerUp = ResetableTile:extend {
    x = 0, 
    y = 0, 
    width = 32,
    height = 32,
    image="media/arrowup.png",
    onCollide = function (self, other)
        other.hasJumpPowerUp= true
        playSfx("media/powerup.ogg")
        self:die()
    end
}

GunPowerUp = ResetableTile:extend {
    x = 0, 
    y = 0, 
    width = 32,
    height = 32,
    image="media/gun.png",
    onCollide = function (self, other)
        other.hasGunPowerUp= true
        playSfx("media/powerup.ogg")
        self:die()
    end
}



defaultFont = {"media/Vdj.ttf", 14}

the.app = App:new {
    onNew = function(self)
        self.stime = love.timer.getTime()
        self.hasInitialized = false
    end,
    clear = function(self)
        if not (self.player == nil) then
            self:remove(self.player)
        end
        if not (self.door == nil) then
            self.door:die()
            self:remove(self.door)
        end
        if not (self.platforms == nil) then
            self:remove(self.platforms)
        end
        if not (self.bottomSpikes == nil) then
            --BUG This doesn't work
            --self:remove(self.bottomSpikes)
            self.bottomSpikes = nil
        end
        --    if not (self.topSpikes == nil) then
        --        --BUG This doesn't work
        --        --self:remove(self.topSpikes)
        --        self.topSpikes = nil
        --    end
        --    if not (self.sideSpikes == nil) then
        --        --self:remove(self.sideSpikes)
        --        self:remove(self.sideSpikes)
        --    end
    end,
    startStory = function(self, storyArray)
        storyMode = true
        --self.storyBackground = Fill:new{x=0, y=the.app.height-100, height=100, width=the.app.width, fill={0,0,0}}
        self.storyBackground = Fill:new{x=0, y=the.app.height/2-100, height=100, width=the.app.width, fill={0,0,0}}
        self:add(self.storyBackground)

        --self.storyText = Text:new{x=25, y=the.app.height-75, tint={200,197,200}, font={"media/Vdj.ttf", 14}, width=the.app.width, text=storyArray[0]}
        --self.storyText = Text:new{x=25, y=the.app.height-75, tint={1,1,1}, font={"media/Vdj.ttf", 14}, width=the.app.width, text=storyArray[0]}
        xOffset = 25
        yOffset = 25
        self.storyExplanationText = Text:new{x=self.storyBackground.x+xOffset, y=self.storyBackground.y+yOffset+50, tint={1,1,1}, font=defaultFont, width=the.app.width-50, text="Press Space"}
        self:add(self.storyExplanationText)
        self.storyText = Text:new{x=self.storyBackground.x+xOffset, y=self.storyBackground.y+yOffset, tint={1,1,1}, font=defaultFont, width=the.app.width-50, text=storyArray[0]}
        self.storyTexts = {}
        for i=2, #storyArray+1 do
            self.storyTexts[i-1] = Text:new{
                x=self.storyBackground.x+xOffset, 
                y=self.storyBackground.y+yOffset,
                tint={1,1,1}, 
                font=defaultFont, 
                width=the.app.width-50, 
                text=storyArray[i-1]}
        end
        self:add(self.storyText)
    end,
    pumpStory = function(self)
        if the.keys:justPressed(' ') then
            playSfx("media/blip.ogg")
            if #self.storyTexts == 0 then
                storyMode = false
                self.storyText:die()
                self.storyExplanationText:die()
                self.storyBackground:die()
            else
                self.storyText:die()
                self.storyText = table.remove(self.storyTexts, 1)
                self:add(self.storyText)
            end
        end
    end,
    
    loadLevel = function(self, level) 
        self.background = Fill:new{x=0, y=0, width=the.app.width, height=the.app.height}
        self:add(self.background)
        if level == 1 then
            self.platforms = Group:new()
            self.platforms:add(Platform:new{x=0,y=400, width=50 })
            self.platforms:add(Platform:new{x=0,y=400+Platform.height, width=the.app.width})
            self.platforms:add(Platform:new{x=0+70,y=400, width=10})
            --window
            window = Tile:new{x=70, y=200, image="media/window.png"}
            self:add(window)
            --self.platforms:add(Platform:new{x=250,y=400 })
            --self.platforms:add(Platform:new{x=400,y=500, width=200})
            --self.platforms:add(Platform:new{x=600,y=400, width=100})
            --self.platforms:add(Platform:new{x=700,y=400, width=100})
            --self.platforms:add(Platform:new{x=100,y=400, width=600})
            --self.platforms:add(Platform:new{x=100,y=400, width=600})
            self:add(self.platforms)

            self.door = Door:new{x=600,y=400+Platform.height-Door.height}
            self:add(self.door)

            self.player = Player:new{x=0,y=400-Player.height}
            self:add(self.player)

            --[[
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
            --]]
            --self.storyText = Text:new{x=0, y=the.app.height-100, text="M: This is a sample story"}
            storyArray = {}
            storyArray[0] = "T: You must remember to control yourself M. "
            storyArray[1] = "M: Oh wait, good point. How do I control myself here?"
            storyArray[2] = "T: *sigh* "
            storyArray[3] = "T: Arrow keys to move left and right. Spacebar to jump and move through green doors."
            storyArray[4] = "M: Thanks!"
            storyArray[5] = "T: Now, I want you to do what you did when you woke up that day."
            storyArray[6] = "M: ..."
            storyArray[7] = "M: I woke up and made my way outside as normal."
            self:startStory(storyArray)
            self.music = playMusic("media/ambient_sweetness.ogg")
        elseif level == 2 then
            --stairs 
            self:clear()

            self.platforms = Group:new()
            stairX = 0
            stairY = 50
            stairWidth = 20
            stairHeight = 10
            nStairs = 35
            for i=1,nStairs do
                self.platforms:add(Platform:new{x=stairX + ((i-1)*stairWidth),y=stairY+((i-1)*stairHeight), width=stairWidth, height=stairHeight})
            end
            self.platforms:add(Platform:new{x=stairX + ((nStairs)*stairWidth),y=stairY+((nStairs)*stairHeight), width=100, height=stairHeight})
            self:add(self.platforms)

            self.door = Door:new{x=stairX + ((nStairs)*stairWidth) + 50,y=stairY+((nStairs)*stairHeight)-Door.height}
            self:add(self.door)

            self.player = Player:new{x=stairX,y=stairY-Player.height}
            self:add(self.player)

            storyArray = {}
            storyArray[0] = "M: I went downstairs."
            storyArray[1] = "M: I like stairs."
            storyArray[2] = "T: ..."
            self:startStory(storyArray)
        elseif level == 3 then
            --outside 1 
            self:clear()

            self.platforms = Group:new()
            self.platforms:add(Platform:new{x=0,y=the.app.height-Platform.height})
            self.platforms:add(Platform:new{x=200,y=550})
            self.platforms:add(Platform:new{x=400,y=525})
            self.platforms:add(Platform:new{x=630,y=500})
            self:add(self.platforms)

            self.door = Door:new{x=675, y=500-Door.height}
            self:add(self.door)

            self.player = Player:new{x=0,y=the.app.height-Platform.height-Player.height}
            self:add(self.player)

            storyArray = {}
            storyArray[0] = "M: Outside, it was a warm spring day. I hate spring."
            storyArray[1] = "T: Me too, I'm more of a winter person." 
            storyArray[2] = "M: I started my long walk to school."
            self:startStory(storyArray)
        elseif level == 4 then
            --outside 2
            self:clear()

            self.platforms = Group:new()
            height = 350
            self.platforms:add(Platform:new{x=0,y=the.app.height-Platform.height})
            self.platforms:add(Platform:new{x=150,y=height, width=Platform.height, height=the.app.height-height-50})
            self.platforms:add(Platform:new{x=150+Platform.height,y=height, width=300})
            self.platforms:add(Platform:new{x=700, y=height})
            self:add(self.platforms)

            self.door = Door:new{x=750, y=height-Door.height}
            self:add(self.door)
            self.door.active=false
            self.door.visible=false

            self.jumpPowerUp = JumpPowerUp:new{x=350, y=height-JumpPowerUp.height- 10}
            self:add(self.jumpPowerUp)

            self.player = Player:new{x=0,y=the.app.height-Platform.height-Player.height}
            self:add(self.player)

            storyArray = {}
            storyArray[0] = "T: You climb that to get to school?"
            storyArray[1] = "M: Sure, it's pretty easy. I just hold right to grab onto the wall and continue jumping."
            self:startStory(storyArray)
            self.shownPowerUp = false
        elseif level == 5 then
            --Close to school
            self:clear()

            self.platforms = Group:new()
            self.platforms:add(Platform:new{x=0,y=the.app.height-Platform.height})
            self:add(self.platforms)

            self.bottomSpikes = Group:new()
            startX = Platform.width
            startY = the.app.height - Spike.height
            n_spikes = 9
            --bottom spikes
            for i=1, n_spikes do
                self.bottomSpikes:add(Spike:new{x=startX + (i-1)*Spike.width, y=startY, flipY = true})
            end
            self:add(self.bottomSpikes)

            -- PLATFROM AFTER SPIKES
            self.platforms:add(Platform:new{x=(n_spikes*Spike.width)+Platform.width,y=the.app.height-Platform.height, width=0.66*Platform.width})

            topHeight = the.app.height/3 - 40
            self.platforms:add(Platform:new{x=(n_spikes*Spike.width)+(Platform.width*2),y=2*the.app.height/3})
            self.platforms:add(Platform:new{x=(n_spikes*Spike.width)+(Platform.width*2),y=topHeight})
            self.platforms:add(Platform:new{x=2*Platform.width/3 -10,y=topHeight})
            self.platforms:add(Platform:new{x=2*Platform.width/3 -10,y=the.app.height/2})

            self.door = Door:new{x=2*Platform.width/3 -10 + 50,y=the.app.height/2-Door.height}
            self:add(self.door)

            self.player = Player:new{x=0,y=the.app.height-Platform.height-Player.height, hasJumpPowerUp=true}
            self:add(self.player)

            storyArray = {}
            storyArray[0] = "M: Coming up to school now. I see some of the triangles."
            storyArray[1] = "T: Who are the triangles?"
            storyArray[2] = "M: ..."
            storyArray[3] = "M: I avoid them."
            self:startStory(storyArray)
        elseif level == 6 then
            --Lunch time (spikes falling)
            self:clear()

            self.platforms = Group:new()
            startingPlatform = Platform:new{x=0,y=the.app.height/8, width=350}
            -- start and end platforms
            self.platforms:add(startingPlatform)
            endingPlatform = Platform:new{x=the.app.width-Platform.width,y=the.app.height/3}
            self.platforms:add(endingPlatform)
            --other platforms
            platformWidth=Platform.width/6
            startX = 128
            --below start
            self.platforms:add(Platform:new{x=startX, y=the.app.height/3, width=264})
            --small ones
            self.platforms:add(Platform:new{x=50, y=2*the.app.height/3, width=platformWidth})
            self.platforms:add(Platform:new{x=startX, y=the.app.height - Platform.height, width=platformWidth})
            self.platforms:add(Platform:new{x=2*the.app.width/3 - 50, y=the.app.height - Platform.height, width=platformWidth})
            self.platforms:add(Platform:new{x=2*the.app.width/3 + 50, y=2*the.app.height/3, width=platformWidth})
            --blocking middle
            self.platforms:add(Platform:new{x=the.app.width/2 - Platform.height/2, y=-(the.app.height/2), width=Platform.height, height=the.app.height/2+(the.app.height/3+Platform.height)})
            self:add(self.platforms)

            self.door = Door:new{x=endingPlatform.x + endingPlatform.width/2 - (Door.width/2),y=endingPlatform.y - Door.height}
            self:add(self.door)

            --Spikes
            self.topSpikes = Group:new()
            startX = 450
            n_spikes = 10
            --top spikes
            for i=1, n_spikes do
                self.topSpikes:add(Spike:new{x=startX + (i-1)*Spike.width})
            end
            --One above the two small ones on the left
            self.topSpikes:add(Spike:new{x=50, y=startingPlatform.y+Platform.height})
            self.topSpikes:add(Spike:new{x=128, y=the.app.height/3+Platform.height})
            self:add(self.topSpikes)

            --Usually this is good
            --self.player = Player:new{x=startingPlatform.x + startingPlatform.width/2 - (Player.width/2),y=startingPlatform.y - Player.height, hasJumpPowerUp=true}
            self.player = Player:new{x=0,y=startingPlatform.y - Player.height, hasJumpPowerUp=true}
            self:add(self.player)

            storyArray = {}
            storyArray[0] = "T: Where are we now?"
            storyArray[1] = "M: This is lunchtime at school."
            storyArray[2] = 'M: The triangles have a "game" where they all try and jump on me.'
            storyArray[3] = "M: I don't like lunchtime."
            self:startStory(storyArray)
        elseif level == 7 then
            --Lunch time, spikes chasing
            self:clear()

            self.platforms = Group:new()
            startingPlatform = Platform:new{x=0,y=the.app.height/8, width=650}
            -- start and end platforms
            self.platforms:add(startingPlatform)
            endingPlatform = Platform:new{x=the.app.width-Platform.width,y=the.app.height-Platform.height}
            self.platforms:add(endingPlatform)
            --other platforms
            platformWidth=Platform.width/3
            startX = 128
            self.platforms:add(Platform:new{x=1*the.app.width/4, y=the.app.height/4, width=3*the.app.width/4})
            self.platforms:add(Platform:new{x=1*the.app.width/8, y=3*the.app.height/8, width=3*the.app.width/4})
            --
            self.platforms:add(Platform:new{x=3*the.app.width/8, y=4*the.app.height/8, width=5*the.app.width/8})
            self.platforms:add(Platform:new{x=1*the.app.width/4, y=5*the.app.height/8, width=2*the.app.width/4})
            --
            self.platforms:add(Platform:new{x=7*the.app.width/16, y=6*the.app.height/8, width=9*the.app.width/16})
            self.platforms:add(Platform:new{x=3*the.app.width/8, y=7*the.app.height/8, width=3*the.app.width/8})

            self:add(self.platforms)

            self.door = Door:new{x=endingPlatform.x + endingPlatform.width/2 - (Door.width/2),y=endingPlatform.y - Door.height}
            self:add(self.door)

            --side spikes
            self.sideSpikes = Group:new()
            n_spikes = (600 / 32)+1
            for i=1, n_spikes do
                spike = Spike:new{x=0, y=(i-1)*Spike.height, rotation=math.rad(-90)}
                self.sideSpikes:add(spike)
            end
            self:add(self.sideSpikes)

            --Usually this is good
            --self.player = Player:new{x=startingPlatform.x + startingPlatform.width/2 - (Player.width/2),y=startingPlatform.y - Player.height, hasJumpPowerUp=true}
            self.player = Player:new{x=100,y=startingPlatform.y - Player.height, hasJumpPowerUp=true}
            self:add(self.player)

            storyArray = {}
            storyArray[0] = "M: I was playing chess with a friend when they came for me."
            storyArray[1] = "T: The triangles?"
            storyArray[2] = 'M: Yeah, they said their leader wanted to talk to me.'
            storyArray[3] = "M: I ran."
            self:startStory(storyArray)
        elseif level == 8 then
            --Local lake
            self:clear()

            platformWidth=Platform.width/4
            self.platforms = Group:new()
            startingPlatform = Platform:new{x=0,y=the.app.height - 100, width = platformWidth}
            -- start and end platforms
            self.platforms:add(startingPlatform)
            endingPlatform = Platform:new{x=the.app.width-Platform.width,y=the.app.height-Platform.height}
            self.platforms:add(endingPlatform)
            --other platforms
            startX = 128
            self.platforms:add(Platform:new{x=1*the.app.width/4 - 20, y=the.app.height/2, width=platformWidth})
            self.platforms:add(Platform:new{x=2*the.app.width/3, y=the.app.height/2, width=platformWidth})
            powerupPlatform = Platform:new{x=3*the.app.width/8, y=the.app.height/8 + 10, width=platformWidth*3}
            self.platforms:add(powerupPlatform)

            self:add(self.platforms)

            self.gunPowerUp = GunPowerUp:new{x=powerupPlatform.x + powerupPlatform.width/2, y=powerupPlatform.y-GunPowerUp.height}
            self:add(self.gunPowerUp)
            self.shownGunPowerUp=false

            --Only add door when get item
            self.door = Door:new{x=endingPlatform.x + endingPlatform.width/2 - (Door.width/2),y=endingPlatform.y - Door.height}
            self:add(self.door)
            self.door.visible=false
            self.door.active=false

            --Usually this is good
            self.player = Player:new{x=startingPlatform.x + startingPlatform.width/2 - (Player.width/2),y=startingPlatform.y - Player.height, hasJumpPowerUp=true, moveMode="onlyJump"}
            --self.player = Player:new{x=100,y=startingPlatform.y - Player.height, hasJumpPowerUp=true}
            self:add(self.player)

            storyArray = {}
            storyArray[0] = "M: I ran to the lakeside."
            storyArray[1] = "M: OW!"
            storyArray[2] = "M: I fell and hurt my leg on a rock."
            storyArray[3] = "M: I could only jump the rest of the way."
            self:startStory(storyArray)
        elseif level == 9 then
            --Final Boss
            self:clear()

            self.platforms = Group:new()
            -- start and end platforms
            startingPlatform = Platform:new{x=the.app.width/4,y=the.app.height/2, width = the.app.width/2}
            self.platforms:add(startingPlatform)
            endingPlatform = startingPlatform
            --other platforms
            startX = 128
            platformWidth = 100
            self.platforms:add(Platform:new{x=1*the.app.width/2 - Platform.width/2, y=the.app.height/4, width=platformWidth})
            --self.platforms:add(Platform:new{x=1*the.app.width/4 - 20, y=the.app.height/2, width=platformWidth})
            --self.platforms:add(Platform:new{x=2*the.app.width/3, y=the.app.height/2, width=platformWidth})

            self:add(self.platforms)

            --Only add door when get item
            self.door = Door:new{x=endingPlatform.x + endingPlatform.width/2 - (Door.width/2),y=endingPlatform.y - Door.height}
            self:add(self.door)
            self.door.visible=false
            self.door.active=false

            --Usually this is good
            self.player = Player:new{x=startingPlatform.x + startingPlatform.width/8,y=startingPlatform.y - Player.height, hasJumpPowerUp=true, hasGunPowerUp=true}
            --self.player = Player:new{x=100,y=startingPlatform.y - Player.height, hasJumpPowerUp=true}
            self:add(self.player)

            self.boss = Boss:new{x=the.app.width/2, y=startingPlatform.y - Boss.height, player=self.player}
            self.boss.active = false
            self:add(self.boss) 

            storyArray = {}
            storyArray[0] = "M: With my hurt leg they eventually caught up to me."
            storyArray[1] = "T: Oh no, what did they do?"
            storyArray[2] = "M: They carried me away and told me I was going to fight their leader."
            storyArray[3] = "M: My leg started to feel better."
            storyArray[4] = "M: I was ready."
            self:startStory(storyArray)
        elseif level == 10 then
            -- Puzzle Level
            self:clear()

            self.platforms = Group:new()
            borderSize = 100
            --Borders
            self.platforms:add(Platform:new{x=0,y=0,width=borderSize, height=the.app.height})
            self.platforms:add(Platform:new{x=the.app.width-borderSize,y=0,width=borderSize, height=the.app.height})
            deltaY = 300
            nWaves = 8
            -- vertical ones
            for i=1,nWaves,2 do
                --wave one
                self.platforms:add(Platform:new{x=borderSize + 100,y=100 - ((i-1)*deltaY),width=500, height=16, squashMode="vertical"})
                self.platforms:add(Platform:new{x=borderSize + 100,y=500 + ((i-1)*deltaY),width=500, height=16, squashMode="vertical"})
                --wave two
                self.platforms:add(Platform:new{x=borderSize,y=100 - ((i)*deltaY),width=500, height=16, squashMode="vertical"})
                self.platforms:add(Platform:new{x=borderSize,y=500 + ((i)*deltaY),width=500, height=16, squashMode="vertical"})
            end
            --[[
            self.platforms:add(Platform:new{x=borderSize,y=-200,width=500, height=16, squashMode="vertical"})
            self.platforms:add(Platform:new{x=borderSize,y=800,width=500, height=16, squashMode="vertical"})
            self.platforms:add(Platform:new{x=borderSize+100,y=-500,width=500, height=16, squashMode="vertical"})
            self.platforms:add(Platform:new{x=borderSize+100,y=1100,width=500, height=16, squashMode="vertical"})
            self.platforms:add(Platform:new{x=borderSize,y=-500,width=500, height=16, squashMode="vertical"})
            self.platforms:add(Platform:new{x=borderSize,y=1100,width=500, height=16, squashMode="vertical"})
            --]]
            --self.platforms:add(Platform:new{x=-200,y=100,width=100, width=16, height = the.app.height-100, squashMode="horizontal"})
            --self.platforms:add(Platform:new{x=the.app.width+200,y=100,width=16, height = the.app.height-100, squashMode="horizontal"})
            self:add(self.platforms)
            self.platforms.active = false

            --[[
            self:remove(self.door)
            self.door = Door:new{x=the.app.width/2 - (Door.width/2),y=the.app.height/2 - Door.height}
            self:add(self.door)
            self.door.active=false
            self.door.visible=false
            --]]

            self.player = Player:new{x=the.app.width/2, y=the.app.height/2, acceleration={x=0, y=0}, moveMode="topdown" }
            self:add(self.player) 

            storyArray = {}
            storyArray[0] = "T: M!"
            storyArray[1] = "T: *....*.*.* "
            storyArray[2] = "T: I'm losing you, we must have found what the cause of your pain was."
            storyArray[3] = "T: But your brain is going into overdrive, it is trying to kill you! "
            storyArray[4] = "T: You need to get out of this dream NOW...*.*"
            self:startStory(storyArray)
            self.hasInitialized = true
        elseif level == 11 then
            --Local lake
            self:clear()

            self.putUpCredits = false
            self.shownEndingStory = false

            self.platforms = Group:new()
            startingPlatform = Platform:new{x=0,y=the.app.height/8, width=200}
            -- start and end platforms
            self.platforms:add(startingPlatform)
            endingPlatform = Platform:new{x=the.app.width-Platform.width,y=the.app.height-Platform.height}
            self.platforms:add(endingPlatform)
            self:add(self.platforms)

            -- Add T
            self.t = T:new{x=endingPlatform.x + endingPlatform.width/2 - (T.width/2),y=endingPlatform.y - T.height}
            self:add(self.t)

            --Usually this is good
            self.player = Player:new{x=startingPlatform.x + startingPlatform.width/2 - (Player.width/2),y=startingPlatform.y - Player.height, hasJumpPowerUp=true, hasGunPowerUp=true}
            --self.player = Player:new{x=100,y=startingPlatform.y - Player.height, hasJumpPowerUp=true}
            self:add(self.player)

            storyArray = {}
            storyArray[0] = "M: ..."
            self:startStory(storyArray)
        end
            --[[
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
            --]]
    end,
    onRun = function (self)
        self.title = Title:new{}
        self:add(self.title)
        self.started = false
        self.state = "title"
    end,
    checkStory = function(self)
        if(storyMode) then
            self:pumpStory()
        end
    end,
    checkNextLevel = function(self)
        if the.keys:justPressed(' ') then
            if self.player.isOverDoor then
                playSfx('media/levelFinish.ogg')
                self.level = self.level + 1
                self:loadLevel(self.level)
            end
        end
    end,

    defaultLevelUpdate = function(self)
        -- default
        self.platforms:collide(self.player)
        self.door:collide(self.player)
        self:checkStory()
        self:checkNextLevel()
        if not (self.bottomSpikes == nil) then
            self.bottomSpikes:collide(self.player)
        end
    end,
    onUpdate = function (self, elapsed)
        if the.keys:pressed('escape') then
            self.quit()
        end

        if DEBUG then
            if the.keys:pressed('1') then
                self.started = true
                self.level = 1
                self:loadLevel(self.level)
            elseif the.keys:pressed('2') then
                self.started = true
                self.level = 2
                self:loadLevel(self.level)
            elseif the.keys:pressed('3') then
                self.started = true
                self.level = 3
                self:loadLevel(self.level)
            elseif the.keys:pressed('4') then
                self.started = true
                self.level = 4
                self:loadLevel(self.level)
            elseif the.keys:pressed('5') then
                self.started = true
                self.level = 5
                self:loadLevel(self.level)
            elseif the.keys:pressed('6') then
                self.started = true
                self.level = 6
                self:loadLevel(self.level)
            elseif the.keys:pressed('7') then
                self.started = true
                self.level = 7
                self:loadLevel(self.level)
            elseif the.keys:pressed('8') then
                self.started = true
                self.level = 8
                self:loadLevel(self.level)
            elseif the.keys:pressed('9') then
                self.started = true
                self.level = 9
                self:loadLevel(self.level)
            elseif the.keys:pressed('q') then
                self.started = true
                self.level = 10
                self:loadLevel(self.level)
            elseif the.keys:pressed('w') then
                self.started = true
                self.level = 11
                self:loadLevel(self.level)
            elseif the.keys:pressed('e') then
                self.started = true
                self.level = 12
                self:loadLevel(self.level)
            elseif the.keys:pressed('r') then
                self.started = true
                self.level = 13
                self:loadLevel(self.level)
            elseif the.keys:pressed('t') then
                self.started = true
                self.level = 14
                self:loadLevel(self.level)
            end
        end
        if self.state == "title" then
            if the.keys:justPressed(' ') then
                if not self.started then
                    self.started = true
                    playSfx('media/title.ogg')
                    self:remove(self.title)
                    self.state = "level"
                    self.level = 1
                    --self.level = 2
                    --self.level = 3
                    --self.level = 4
                    self:loadLevel(self.level)
                end
            end
        elseif self.state == "level" then
            if self.level == 1 then
                --bedroom
                self.platforms:collide(self.player)
                self.door:collide(self.player)
                self:checkStory()
                self:checkNextLevel()
                --self.topSpikes:collide(self.player)
                --self.bottomSpikes:collide(self.player)
                --[[
                for k, spike in pairs(self.topSpikes.sprites) do
                    -- move down
                    if roughlyEqual(spike.x, self.player.x, 2.0) then
                        spike.velocity.y = 400
                    end
                end
                --]]
            elseif self.level == 4 then
                self.jumpPowerUp:collide(self.player)
                
                if self.player.hasJumpPowerUp and not self.shownPowerUp then
                    self.shownPowerUp = true
                    storyArray = {}
                    storyArray[0] = "T: You learned how to jump higher that day too?"
                    storyArray[1] = "M: Yep it was pretty good fun. I always learn things on my own."
                    self:startStory(storyArray)
                    self.door.active=true
                    self.door.visible=true
                end
                self:defaultLevelUpdate()
            elseif self.level == 6 then
                self.topSpikes:collide(self.player)
                self:defaultLevelUpdate()
                -- if below a spike
                for k, spike in pairs(self.topSpikes.sprites) do
                    if self.player.y > spike.y then
                        if roughlyEqual(spike.x, self.player.x, 2.0) then
                            -- move down
                            spike.velocity.y = spikeFallingSpeed
                        end
                    end
                end
            elseif self.level == 7 then
                self:defaultLevelUpdate()
                self.sideSpikes:collide(self.player)
                for k, spike in pairs(self.sideSpikes.sprites) do
                    if(not storyMode) then
                        spike.velocity.x = sideSpikeSpeed
                    end
                end
            elseif self.level == 8 then
                self.gunPowerUp:collide(self.player)
                
                if self.player.hasGunPowerUp and not self.shownGunPowerUp then
                    self.shownGunPowerUp = true
                    storyArray = {}
                    storyArray[0] = "T: Oh, you found a gun!"
                    storyArray[1] = "M: Yeah. I'm normally a pacifist, but this time I thought they had gone too far."
                    storyArray[2] = "M: I hung onto it."
                    storyArray[3] = "T: You know you have to press 'a' to fire that thing right?"
                    storyArray[4] = "T: Not that I approve of you using a gun or anything..."
                    self:startStory(storyArray)
                    self.door.active=true
                    self.door.visible=true
                end
                self:defaultLevelUpdate()
            elseif self.level == 9 then
                self:defaultLevelUpdate()
                if not (self.bullets == nil) then
                    self.bullets:collide(self.boss)
                end
                if self.boss.dead then
                    self.door.active=true
                    self.door.visible=true
                end
                self.boss:collide(self.player)
                if(not storyMode) then
                    self.boss.active = true
                end
            elseif self.level == 10 then
                self:defaultLevelUpdate()
                if(not storyMode) then
                    self.platforms.active = true
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
                    if nCollisions > 0 then
                        resetNeeded = true
                    end
                    self.platforms:collide(self.player)
                    self.platforms:collide(self.platforms)
                    for k, platform in pairs(self.platforms.sprites) do
                        platform:moveTowardsCentre()
                    end
                end
                
                nPlatforms = 0
                for k, platform in pairs(self.platforms.sprites) do
                    if(platform.active == true) then
                        nPlatforms = nPlatforms + 1
                    end
                end
                if nPlatforms == 2 and self.hasInitialized then
                    self.hasInitialized = false
                    --FINISHED
                    self.door = Door:new{x=the.app.width/2 - (Door.width/2),y=the.app.height/2 - Door.height}
                    self:add(self.door)
                    self:remove(self.player)
                    self.player = Player:new{x=self.player.x, y=self.player.y, moveMode="topdown"}
                    self:add(self.player) 
                end
            elseif self.level == 11 then
                self:defaultLevelUpdate()
                self.t:collide(self.player)
                if self.player.isFinished and not self.shownEndingStory then
                    self.shownEndingStory = true
                    storyArray = {}
                    storyArray[0] = "T: You made it M!"
                    storyArray[1] = "M: Yeah. I feel much better. Thank you doctor."
                    storyArray[2] = "T: It's my pleasure. "
                    storyArray[3] = "T: That bully you mentioned in the story has been dealt with. "
                    storyArray[4] = "T: He won't hurt you again."
                    storyArray[5] = "T: When you wake up we'll all be waiting for you."
                    self:startStory(storyArray)
                end
                if self.player.isFinished and (not storyMode) and (not self.putUpCredits) then
                    self.putUpCredits = true 
                    --Show credits
                    self:add(Tile:new{x=0, y=0, image="media/endCredits.png"})
                    --TODO: Display time taken
                    self.etime = love.timer.getTime()
                    self:add(Text:new{x=65, y=300, tint={1,1,1}, font=defaultFont, width = the.app.width, text = "Time taken (seconds) : " .. (self.etime-self.stime)})
                end
                if self.player.isFinished and (not storyMode) and (self.putUpCredits) then
                    if the.keys:justPressed(' ') then
                        self.state = "title"
                    end
                end
            else
                self:defaultLevelUpdate()
            end
                --[[
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
                        playSfx('media/levelFinish.ogg')
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
            --]]
        end
        if(resetNeeded == true) then
            reset(self.player)
            if not (self.enemies == nil) then
                for k, enemy in pairs(self.enemies.sprites) do
                    reset(enemy)
                end
            end
            if not (self.topSpikes == nil) then
                for k, spike in pairs(self.topSpikes.sprites) do
                    reset(spike)
                end
            end
            if not (self.sideSpikes == nil) then
                for k, spike in pairs(self.sideSpikes.sprites) do
                    reset(spike)
                end
            end
            if not (self.platforms == nil) then
                for k, platform in pairs(self.platforms.sprites) do
                    reset(platform)
                    platform:revive()
                end
            end

            if not (self.boss == nil) then
                reset(self.boss)
            end

            resetNeeded = false
        end
        --Firing
        if the.keys:justPressed('a') and self.player.hasGunPowerUp and (not storyMode) then
            self:fire(self.player)
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
        if self.bullets == nil then
            self.bullets = Group:new()
            self:add(self.bullets)
        end
        self.bullets:add(Bullet:new{x=x, y=player.y+10, velocity={x=bulletVel} })
        playSfx("media/shoot.ogg")
    end
}
