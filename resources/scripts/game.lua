-- Leo Engine Lua Game - Minimal Port of tiled_demo.c
-- Using only the available Lua API functions

-- Game state
local player = {
    x = 100,
    y = 100,
    size = 32,
    speed = 150,
    alive = true
}

local enemies = {}
local particles = {}

-- Initialize game
function leo_init()
    print("Leo Lua Game initialized")
    
    -- Test keyboard constants
    if KEY_A then
        print("Keyboard constants available")
    else
        print("Keyboard constants not available, using mouse controls")
    end
    
    -- Create some enemies
    for i = 1, 5 do
        table.insert(enemies, {
            x = math.random(200, 600),
            y = math.random(200, 400),
            size = 32,
            speed = 30,
            dir_x = math.random(-1, 1),
            dir_y = math.random(-1, 1),
            change_timer = math.random(1, 3)
        })
    end
    
    -- Create particles
    for i = 1, 100 do
        table.insert(particles, {
            x = math.random(0, 800),
            y = math.random(0, 600),
            vel_x = (math.random() - 0.5) * 60,
            vel_y = math.random(20, 50),
            flash_timer = math.random() * 10
        })
    end
    
    return true
end

-- Update game logic
function leo_update(dt)
    if not player.alive then
        -- Check for respawn
        if leo_is_key_released and leo_is_key_released(KEY_R) then
            player.x = 100
            player.y = 100
            player.alive = true
        end
        return
    end
    
    -- Keyboard movement (test if keyboard API exists)
    local dx, dy = 0, 0
    if leo_is_key_down then
        if leo_is_key_down(KEY_A) or leo_is_key_down(KEY_LEFT) then dx = -1 end
        if leo_is_key_down(KEY_D) or leo_is_key_down(KEY_RIGHT) then dx = 1 end
        if leo_is_key_down(KEY_W) or leo_is_key_down(KEY_UP) then dy = -1 end
        if leo_is_key_down(KEY_S) or leo_is_key_down(KEY_DOWN) then dy = 1 end
        
        player.x = player.x + dx * player.speed * dt
        player.y = player.y + dy * player.speed * dt
    else
        -- Fallback to mouse movement
        local mouse_x = leo_get_mouse_x()
        local mouse_y = leo_get_mouse_y()
        
        if leo_is_mouse_button_down(LEO_MOUSE_BUTTON_LEFT) then
            local mdx = mouse_x - player.x - player.size/2
            local mdy = mouse_y - player.y - player.size/2
            local dist = math.sqrt(mdx*mdx + mdy*mdy)
            
            if dist > 5 then
                player.x = player.x + (mdx/dist) * player.speed * dt
                player.y = player.y + (mdy/dist) * player.speed * dt
            end
        end
    end
    
    -- Check for quit
    if leo_is_key_pressed and leo_is_key_pressed(KEY_ESCAPE) then
        leo_quit()
    end
    
    -- Keep player in bounds
    if player.x < 0 then player.x = 0 end
    if player.y < 0 then player.y = 0 end
    if player.x > 800 - player.size then player.x = 800 - player.size end
    if player.y > 600 - player.size then player.y = 600 - player.size end
    
    -- Update enemies
    for _, enemy in ipairs(enemies) do
        enemy.change_timer = enemy.change_timer - dt
        if enemy.change_timer <= 0 then
            enemy.dir_x = math.random(-1, 1)
            enemy.dir_y = math.random(-1, 1)
            enemy.change_timer = math.random(1, 3)
        end
        
        enemy.x = enemy.x + enemy.dir_x * enemy.speed * dt
        enemy.y = enemy.y + enemy.dir_y * enemy.speed * dt
        
        -- Keep enemies in bounds
        if enemy.x < 0 or enemy.x > 800 - enemy.size then
            enemy.dir_x = -enemy.dir_x
        end
        if enemy.y < 0 or enemy.y > 600 - enemy.size then
            enemy.dir_y = -enemy.dir_y
        end
        
        -- Check collision with player
        local dx = enemy.x - player.x
        local dy = enemy.y - player.y
        if dx*dx + dy*dy < (enemy.size + player.size)*(enemy.size + player.size)/4 then
            player.alive = false
        end
    end
    
    -- Update particles
    for _, particle in ipairs(particles) do
        particle.x = particle.x + particle.vel_x * dt
        particle.y = particle.y + particle.vel_y * dt
        particle.flash_timer = particle.flash_timer + dt
        
        -- Reset particle when it falls off screen
        if particle.y > 650 then
            particle.x = math.random(0, 800)
            particle.y = -50
            particle.vel_x = (math.random() - 0.5) * 60
            particle.vel_y = math.random(20, 50)
        end
        
        -- Wrap horizontally
        if particle.x < -10 then particle.x = 810 end
        if particle.x > 810 then particle.x = -10 end
    end
end

-- Render game
function leo_render()
    -- Clear background to dark blue
    leo_clear_background(32, 32, 64, 255)
    
    -- Draw particles
    for _, particle in ipairs(particles) do
        local flash = 0.5 + 0.5 * math.sin(particle.flash_timer * 3)
        local alpha = math.floor(180 * flash)
        leo_draw_circle(math.floor(particle.x), math.floor(particle.y), 1.5, 255, 140, 0, alpha)
    end
    
    -- Draw player
    if player.alive then
        leo_draw_rectangle(math.floor(player.x), math.floor(player.y), player.size, player.size, 0, 255, 0, 255)
    else
        -- Draw dead player in red
        leo_draw_rectangle(math.floor(player.x), math.floor(player.y), player.size, player.size, 255, 0, 0, 255)
    end
    
    -- Draw enemies
    for _, enemy in ipairs(enemies) do
        leo_draw_rectangle(math.floor(enemy.x), math.floor(enemy.y), enemy.size, enemy.size, 255, 0, 255, 255)
    end
    
    -- Draw UI text (using rectangles since no text API)
    if not player.alive then
        -- Draw "DEAD" message using rectangles
        leo_draw_rectangle(350, 250, 100, 20, 255, 0, 0, 255)
    end
    
    -- Draw instructions
    leo_draw_rectangle(10, 10, 200, 60, 0, 0, 0, 128)
end

-- Cleanup
function leo_exit()
    print("Leo Lua Game exiting")
end
