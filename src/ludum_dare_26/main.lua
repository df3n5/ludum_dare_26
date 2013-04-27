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

the.app = App:new {
    onRun = function (self)
        self.title = Title:new{}
        self:add(self.title)
        self.started = false
    end,
    onUpdate = function (self, elapsed)
        if the.keys:pressed('escape') then
            self.quit()
        elseif the.keys:justPressed(' ') then
            if not self.started then
                self.started = true
                playSound('media/title.wav')
                -- TODO: Transition to next scene
            end
        end
    end
}
