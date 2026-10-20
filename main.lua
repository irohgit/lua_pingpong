-- CONSTANTS
local BALL_SIZE = 20
local PADDLE_HEIGHT = 100
local PADDLE_THICKNESS = BALL_SIZE
local PADDLE_PADDING = 2*BALL_SIZE
local PADDLE_SPEED = 150
local DIGIT_SIZE = BALL_SIZE/2
local DEBUG_MODE = true -- Master DEBUG Gate: Set to false when releasing

-- FUNCTIONS
local drawDivider, renderDigit
-- VARIABLES
local debug_view = false -- Debug Overlay

local ball_x,ball_y = 100,100 -- Initial Ball Position
local ball_dx,ball_dy = 500,500 -- Derivative for movement
local paddle_left_y = 0
local paddle_right_y = 0
local paddle_speed = 100
local dividerSegments = 21
local dividerWidth = 5 
local joystick_left = nil
local joystick_right = nil
local window_width_draw = love.graphics.getWidth()
local window_height_draw = love.graphics.getHeight()
local bottom_of_paddle_left = 0
local bottom_of_paddle_right = 0
local top_of_paddle_left = 0
local top_of_paddle_right = 0
local score_left = 0
local score_right = 0

local digits = {
   [0] = {{1,1,1}, {1,0,1}, {1,0,1}, {1,0,1}, {1,1,1}},
   [1] = {{0,1,0}, {1,1,0}, {0,1,0}, {0,1,0}, {0,1,0}},
   [2] = {{1,1,1}, {0,0,1}, {1,1,1}, {1,0,0}, {1,1,1}},
   [3] = {{1,1,1}, {0,0,1}, {1,1,1}, {0,0,1}, {1,1,1}},
   [4] = {{1,0,1}, {1,0,1}, {1,1,1}, {0,0,1}, {0,0,1}},
   [5] = {{1,1,1}, {1,0,0}, {1,1,1}, {0,0,1}, {1,1,1}},
   [6] = {{1,1,1}, {1,0,0}, {1,1,1}, {1,0,1}, {1,1,1}},
   [7] = {{1,1,1}, {0,0,1}, {0,0,1}, {0,0,1}, {0,0,1}},
   [8] = {{1,1,1}, {1,0,1}, {1,1,1}, {1,0,1}, {1,1,1}},
   [9] = {{1,1,1}, {1,0,1}, {1,1,1}, {0,0,1}, {1,1,1}},
}
--HELPER FUNCTIONS
local function debugOnly(fn,...)
    if DEBUG_MODE and debug_view then return fn(...) end
end

--[[ LUA NOTES
Lua finds names at runtime, (looked up when the line runs).
In Lua, libraries such as Table is already global. Or we use the keyword "require". THis is different to c++ when we #include things.
--]]
--Developer Tools: 

local function toggleDebug()
    if DEBUG_MODE then
        debug_view = not debug_view
    end
end

function love.keypressed(key)
    if key == "f1" then toggleDebug() end
end

function love.gamepadpressed(joystick,button)
    if button == "back" then toggleDebug() end
end

function drawDebug()
    local lines = {
       "FPS: "..love.timer.getFPS(),
       "BALL_POSITION: "..string.format("%.0f,%.0f",ball_x,ball_y),
       "CONTROLLERS_CONNECTED: "..string.format("%s",love.joystick.getJoystickCount()).." "..(joystick_left and joystick_left:getName() or "none").." "..(joystick_right and joystick_right:getName() or "none"),
    }
    love.graphics.printf(table.concat(lines,"\n"),10,window_height_draw-100,window_width,"left")
end
--Player/s Control Setup
function love.load()
    joystick_left = love.joystick.getJoysticks()[1]
    joystick_right = love.joystick.getJoysticks()[2]
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
    
    -- TODO: Display scores larger than 9
    -- Draw Player 1 Score
    render_digit(digits[score_left] ,window_width_draw/2 - 6*DIGIT_SIZE,0)
    -- Draw Player 2 Score
    render_digit(digits[score_right] ,window_width_draw/2 + 3*DIGIT_SIZE,0)

    debugOnly(drawDebug)
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
    -- TODO: ball collision with the paddles 
    -- TODO: limit paddle movement to within the screen
    -- TODO: score system
    -- INPUT
    paddle_left_y = movePaddle(paddle_left_y,getInputDirection("w","s",joystick_left),dt,window_height)
    paddle_right_y = movePaddle(paddle_right_y,getInputDirection("up","down",joystick_right),dt,window_height)
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
end -- END drawDivider Function

function render_digit(digit,x,y)
    for cell_y,row in ipairs(digit) do
        for cell_x,cell in ipairs(row) do
            if cell ~= 0 then
                love.graphics.rectangle("fill",x +(cell_x-1)*DIGIT_SIZE,y+(cell_y-1)*DIGIT_SIZE,DIGIT_SIZE,DIGIT_SIZE)
            end
        end
    end
end -- END render_digit function

function getInputDirection(up_key,down_key,gamepad) -- Returns direction (number)
    local direction = 0
    if love.keyboard.isDown(down_key) or (gamepad and gamepad:isGamepadDown("dpdown")) then
        direction = direction + 1
    end
    if love.keyboard.isDown(up_key)  or (gamepad and gamepad:isGamepadDown("dpup")) then
        direction = direction - 1
    end
    return direction
end -- END getInputDirection Function

function movePaddle(y,direction, dt, window_height) -- -> number
    return clamp(y + direction * PADDLE_SPEED *dt,0,window_height - PADDLE_HEIGHT)
end -- END movePaddle function

function clamp (current_y, window_start, window_height)
    -- We want to ensure the y value can never be greater than window-height minus the paddle length
    return math.max(window_start,math.min(current_y,window_height))
end -- END clamp function

