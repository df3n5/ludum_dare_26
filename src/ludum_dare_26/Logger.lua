--Love2D Logging
Logger = { logs={}, 
    maxLogs=100,
    startPos={x=0,y=0},
    logYDelta=14,
    visible=true}

function Logger:new(o)
    return ObjectNew(o, self)
end

function Logger:insert(msg)
    while #self.logs > self.maxLogs do
        table.remove()
    end
    table.insert(self.logs, msg)
end

function Logger:d(msg)
    self:insert(os.date("%c") .. " DEBUG: " .. msg)
end

function Logger:e(msg)
    self:insert(os.date("%c") .. " ERROR: " .. msg)
end

function Logger:draw()
    if self.visible == true then
        logY = self.startPos.y
        for i=#self.logs, 1, -1 do
            love.graphics.print(self.logs[i], 0, logY)
            logY = logY + self.logYDelta
        end
    end
end
