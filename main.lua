-- CONSTANTS
BALL_SIZE = 50
PADDLE_HEIGHT = 100
PADDLE_THICKNESS = BALL_SIZE
PADDLE_PADDING = 2*BALL_SIZE
-- VARIABLES
ball_x,ball_y = 100,100 -- Initial Ball Position
ball_dx,ball_dy = 500,500 -- Derivative for movement
paddle_left_y = 0
paddle_right_y =0

function love.draw()
    --Store Window Size
    local window_width_draw = love.graphics.getWidth()
    local window_height_draw = love.graphics.getHeight()
    love.graphics.clear(0x18/255,0x18/255,0x18/255,1) -- RGBA Diving by 255 maps 0-255 bytes to LOVE's 0-1 range.
    love.graphics.print("Hello World", 400,400)
    -- Draw Ball
    love.graphics.rectangle("fill",ball_x,ball_y,BALL_SIZE,BALL_SIZE) -- Mode is fill or line
    -- Draw Paddle Left and Right Paddles
    local paddle_left_x = PADDLE_PADDING; -- Derive x as the x value depends on window width.
    love.graphics.rectangle("fill",paddle_left_x,paddle_left_y,PADDLE_THICKNESS, PADDLE_HEIGHT)
    local paddle_right_x = window_width_draw - PADDLE_PADDING - PADDLE_THICKNESS
    love.graphics.rectangle("fill",paddle_right_x,paddle_right_y,PADDLE_THICKNESS, PADDLE_HEIGHT)
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
end --END UPDATE FUNCTION

    
