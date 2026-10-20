-- CONSTANTS
local BALL_SIZE = 50
local PADDLE_HEIGHT = 100
local PADDLE_THICKNESS = BALL_SIZE
local PADDLE_PADDING = 2*BALL_SIZE
local DEBUG_MODE = true
-- VARIABLES
local ball_x,ball_y = 100,100 -- Initial Ball Position
local ball_dx,ball_dy = 500,500 -- Derivative for movement
local paddle_left_y = 0
local paddle_right_y = 0
local paddle_speed = 100
local dividerSegments = 21
local dividerWidth = 5 
local joystick = nil
local window_width_draw = love.graphics.getWidth()
local window_height_draw = love.graphics.getHeight()

--[[ LUA NOTES
Lua finds names at runtime, (looked up when the line runs).
In Lua, libraries such as Table is already global. Or we use the keyword "require". THis is different to c++ when we #include things.
--]]
--Developer Tools: 
function drawDebug()
    local lines = {
       "FPS: "..love.timer.getFPS(),
       "BALL_POSITION: "..string.format("%.0f,%.0f",ball_x,ball_y),
       "CONTROLLERS_CONNECTED: "..string.format("%s",love.joystick.getJoystickCount()).." "..(joystick and joystick:getName() or "none"),
    }
    love.graphics.printf(table.concat(lines,"\n"),10,10,window_width,"left")
end
--Player/s Control Setup
function love.load()
    local joysticks = love.joystick.getJoysticks()
    joystick = joysticks[1]
    print(joystick)
end
function love.draw()
    love.graphics.print("Hello World", 400,400)
    --Store Window Size
    -- Draw Background
    love.graphics.clear(0x25/255,0x30/255,0x25/255,1) -- RGBA Diving by 255 maps 0-255 bytes to LOVE's 0-1 range.
    -- Draw Divider : Note LUA is inclusive. Thus Numeric if for loop includes both start and end.
    drawDivider(dividerSegments,window_width_draw,window_height_draw)
    -- Draw Ball
    love.graphics.rectangle("fill",ball_x,ball_y,BALL_SIZE,BALL_SIZE) -- Mode is fill or line
    -- Draw Paddle Left and Right Paddles
    local paddle_left_x = PADDLE_PADDING; -- Derive x as the x value depends on window width.
    love.graphics.rectangle("fill",paddle_left_x,paddle_left_y,PADDLE_THICKNESS, PADDLE_HEIGHT)
    local paddle_right_x = window_width_draw - PADDLE_PADDING - PADDLE_THICKNESS
    love.graphics.rectangle("fill",paddle_right_x,paddle_right_y,PADDLE_THICKNESS, PADDLE_HEIGHT)
    drawDebug()
end

function love.update(dt)
    --JOB 0:
    window_width = love.graphics.getWidth()
    window_height = love.graphics.getHeight()
    --JOB : Update the ball's x position 
    local ball_newx = ball_x + ball_dx*dt
    if ball_newx < 0 or ball_newx + BALL_SIZE >= window_width then
        ball_dx = -ball_dx
    else
        ball_x = ball_newx
    end
    
    --JOB : Update the ball's y position 
    local ball_newy = ball_y + ball_dy*dt
    if ball_newy < 0 or ball_newy + BALL_SIZE >= window_height then
        ball_dy = -ball_dy
    else
        ball_y = ball_newy
    end
    --JOB 1: Recalculate ball position based on dx and deltaTime
    ball_x = ball_x + ball_dx*dt
    ball_y = ball_y + ball_dy*dt
    if love.keyboard.isDown("s") then
       paddle_left_y = paddle_left_y + paddle_speed*dt 
    end
    if love.keyboard.isDown("w") then
       paddle_left_y = paddle_left_y - paddle_speed*dt 
    end
    
    if love.keyboard.isDown("down") then
       paddle_right_y = paddle_right_y + paddle_speed*dt 
    end
    if love.keyboard.isDown("up") then
       paddle_right_y = paddle_right_y - paddle_speed*dt 
    end
end --END UPDATE FUNCTION

function drawDivider(segments,window_width,window_height)
    --There are n equal segments we only draw every other piece. 
    local segment_length = window_height/segments
    local middle_of_window_x = window_width/2
    --Print every other line for perforated effect.
    for i = 0, segments - 1 do
        if i%2 == 0 then
            love.graphics.setLineWidth(dividerWidth)
            love.graphics.line(middle_of_window_x,i*segment_length,middle_of_window_x,(i+1)*segment_length)
        end
    end
end


