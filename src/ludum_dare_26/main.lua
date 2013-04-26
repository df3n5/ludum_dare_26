require("AnAL")
require("Sprite")
require("Logger")

-- constants
PI = 3.14159

function checkQuit()
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
end

function loadSound(filename)
    data = love.sound.newSoundData(filename)
    return love.audio.newSource(data)
end

function drawGame()
end

-- Do some loading here
function love.load()
    -- Set background appropriately
    love.graphics.setBackgroundColor(155, 100, 100)
    logger = Logger:new()
    titleImage = love.graphics.newImage("title.png")
    titleSound = loadSound("title.wav")
    inTitle = true
end

-- Do some drawing here.
function love.draw()
    if(inTitle) then
        love.graphics.draw(titleImage, 
            0, 
            0)
    else
        drawGame()
    end
    logger:draw()
end

function love.keypressed(key)
    if(inTitle) then
        if key == " " then
            inTitle=false
            love.audio.play(titleSound)
        end
    else
    end
end

function love.update(dt)
    checkQuit()
end
