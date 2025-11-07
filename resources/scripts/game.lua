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
local textures = {}
local tiled_map = nil
local dirt_texture = nil
local tree_texture = nil
local camera = {
    target_x = 100,
    target_y = 100,
    offset_x = 400,
    offset_y = 300,
    rotation = 0,
    zoom = 1.0
}

-- Initialize game
function leo_init()
    print("Leo Lua Game initialized")
    
    -- Test keyboard constants
    if leo_KEY_A then
        print("Keyboard constants available")
    else
        print("Keyboard constants not available, using mouse controls")
    end
    
    -- Try to load textures
    if leo_image_load then
        print("Attempting to load textures...")
        textures.hero = leo_image_load("images/hero_32x32.png")
        textures.enemy = leo_image_load("images/enemy_32x32.png")
        dirt_texture = leo_image_load("images/dirt_32x32.png")
        tree_texture = leo_image_load("images/tree_32x32.png")
        
        if leo_image_is_ready and leo_image_is_ready(textures.hero) then
            print("✅ Hero texture loaded")
        else
            print("❌ Hero texture failed")
            textures.hero = nil
        end
        
        if leo_image_is_ready and leo_image_is_ready(textures.enemy) then
            print("✅ Enemy texture loaded")
        else
            print("❌ Enemy texture failed")
            textures.enemy = nil
        end
        
        if leo_image_is_ready and leo_image_is_ready(dirt_texture) then
            print("✅ Dirt texture loaded")
        else
            print("❌ Dirt texture failed")
            dirt_texture = nil
        end
        
        if leo_image_is_ready and leo_image_is_ready(tree_texture) then
            print("✅ Tree texture loaded")
        else
            print("❌ Tree texture failed")
            tree_texture = nil
        end
    else
        print("Texture loading API not available")
    end
    
    -- Try to load Tiled map
    if leo_tiled_load then
        print("Attempting to load Tiled map...")
        tiled_map = leo_tiled_load("maps/demo.json")
        if tiled_map then
            print("✅ Tiled map loaded")
            local width, height = leo_tiled_map_get_size(tiled_map)
            print("Map size: " .. width .. "x" .. height)
            
            -- Initialize player from map
            local player_layer = leo_tiled_find_object_layer(tiled_map, "player")
            if player_layer then
                local count = leo_tiled_object_layer_get_count(player_layer)
                if count > 0 then
                    local player_obj = leo_tiled_object_layer_get_object(player_layer, 1)
                    -- Check if coordinates are reasonable (within map bounds)
                    local map_width_px = width * 32
                    local map_height_px = height * 32
                    if player_obj.x >= 0 and player_obj.x < map_width_px and 
                       player_obj.y >= 0 and player_obj.y < map_height_px then
                        player.x = player_obj.x
                        player.y = player_obj.y
                        print("✅ Player spawn: (" .. player.x .. ", " .. player.y .. ")")
                    else
                        print("⚠️ Player spawn out of bounds (" .. player_obj.x .. ", " .. player_obj.y .. "), using fallback")
                        player.x = 100
                        player.y = 100
                    end
                    print("Player object details:", player_obj.name, player_obj.type, player_obj.width, player_obj.height)
                else
                    print("⚠️ Using fallback player spawn")
                end
            else
                print("⚠️ No player layer found, using fallback spawn")
            end
            
            -- Initialize enemies from map
            local enemy_layer = leo_tiled_find_object_layer(tiled_map, "enemies")
            if enemy_layer then
                local count = leo_tiled_object_layer_get_count(enemy_layer)
                print("Found " .. count .. " enemies in map")
                for i = 1, count do
                    local enemy_obj = leo_tiled_object_layer_get_object(enemy_layer, i)
                    table.insert(enemies, {
                        x = enemy_obj.x,
                        y = enemy_obj.y,
                        origin_x = enemy_obj.x,
                        origin_y = enemy_obj.y,
                        size = 32,
                        speed = 30,
                        dir_x = math.random(-1, 1),
                        dir_y = math.random(-1, 1),
                        change_timer = math.random(1, 3)
                    })
                end
            else
                print("⚠️ No enemy layer found, creating fallback enemies")
                -- Create fallback enemies
                for i = 1, 5 do
                    table.insert(enemies, {
                        x = math.random(200, 600),
                        y = math.random(200, 400),
                        origin_x = math.random(200, 600),
                        origin_y = math.random(200, 400),
                        size = 32,
                        speed = 30,
                        dir_x = math.random(-1, 1),
                        dir_y = math.random(-1, 1),
                        change_timer = math.random(1, 3)
                    })
                end
            end
        else
            print("❌ Tiled map failed to load")
        end
    else
        print("Tiled map API not available")
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
        if leo_is_key_released and leo_is_key_released(leo_KEY_R) then
            player.x = 100
            player.y = 100
            player.alive = true
        end
        return
    end
    
    -- Keyboard movement with tree collision
    local dx, dy = 0, 0
    if leo_is_key_down then
        if leo_is_key_down(leo_KEY_A) or leo_is_key_down(leo_KEY_LEFT) then dx = -1 end
        if leo_is_key_down(leo_KEY_D) or leo_is_key_down(leo_KEY_RIGHT) then dx = 1 end
        if leo_is_key_down(leo_KEY_W) or leo_is_key_down(leo_KEY_UP) then dy = -1 end
        if leo_is_key_down(leo_KEY_S) or leo_is_key_down(leo_KEY_DOWN) then dy = 1 end
        
        -- Calculate new position
        local new_x = player.x + dx * player.speed * dt
        local new_y = player.y + dy * player.speed * dt
        
        -- Check tree collision
        local blocked = false
        if tiled_map then
            local tree_layer = leo_tiled_find_tile_layer(tiled_map, "tree-layer")
            if tree_layer then
                -- Check corners of player rectangle
                local corners = {
                    {math.floor(new_x / 32), math.floor(new_y / 32)},
                    {math.floor((new_x + 31) / 32), math.floor(new_y / 32)},
                    {math.floor(new_x / 32), math.floor((new_y + 31) / 32)},
                    {math.floor((new_x + 31) / 32), math.floor((new_y + 31) / 32)}
                }
                
                local width, height = leo_tiled_tile_layer_get_size(tree_layer)
                for _, corner in ipairs(corners) do
                    local tile_x, tile_y = corner[1], corner[2]
                    if tile_x >= 0 and tile_x < width and tile_y >= 0 and tile_y < height then
                        local gid = leo_tiled_get_gid(tree_layer, tile_x, tile_y)
                        if gid == 2 then -- Tree tile
                            blocked = true
                            break
                        end
                    end
                end
            end
        end
        
        -- Move if not blocked
        if not blocked then
            player.x = new_x
            player.y = new_y
        else
            -- Try horizontal only
            new_x = player.x + dx * player.speed * dt
            blocked = false
            if tiled_map then
                local tree_layer = leo_tiled_find_tile_layer(tiled_map, "tree-layer")
                if tree_layer then
                    local corners = {
                        {math.floor(new_x / 32), math.floor(player.y / 32)},
                        {math.floor((new_x + 31) / 32), math.floor(player.y / 32)},
                        {math.floor(new_x / 32), math.floor((player.y + 31) / 32)},
                        {math.floor((new_x + 31) / 32), math.floor((player.y + 31) / 32)}
                    }
                    local width, height = leo_tiled_tile_layer_get_size(tree_layer)
                    for _, corner in ipairs(corners) do
                        local tile_x, tile_y = corner[1], corner[2]
                        if tile_x >= 0 and tile_x < width and tile_y >= 0 and tile_y < height then
                            local gid = leo_tiled_get_gid(tree_layer, tile_x, tile_y)
                            if gid == 2 then blocked = true; break end
                        end
                    end
                end
            end
            if not blocked then player.x = new_x end
            
            -- Try vertical only
            new_y = player.y + dy * player.speed * dt
            blocked = false
            if tiled_map then
                local tree_layer = leo_tiled_find_tile_layer(tiled_map, "tree-layer")
                if tree_layer then
                    local corners = {
                        {math.floor(player.x / 32), math.floor(new_y / 32)},
                        {math.floor((player.x + 31) / 32), math.floor(new_y / 32)},
                        {math.floor(player.x / 32), math.floor((new_y + 31) / 32)},
                        {math.floor((player.x + 31) / 32), math.floor((new_y + 31) / 32)}
                    }
                    local width, height = leo_tiled_tile_layer_get_size(tree_layer)
                    for _, corner in ipairs(corners) do
                        local tile_x, tile_y = corner[1], corner[2]
                        if tile_x >= 0 and tile_x < width and tile_y >= 0 and tile_y < height then
                            local gid = leo_tiled_get_gid(tree_layer, tile_x, tile_y)
                            if gid == 2 then blocked = true; break end
                        end
                    end
                end
            end
            if not blocked then player.y = new_y end
        end
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
    if leo_is_key_pressed and leo_is_key_pressed(leo_KEY_ESCAPE) then
        leo_quit()
    end
    
    -- Camera zoom controls
    if leo_is_key_down and leo_is_key_down(leo_KEY_EQUALS) then
        camera.zoom = camera.zoom + 2.0 * dt
        if camera.zoom > 3.0 then camera.zoom = 3.0 end
    end
    if leo_is_key_down and leo_is_key_down(leo_KEY_MINUS) then
        camera.zoom = camera.zoom - 2.0 * dt
        if camera.zoom < 0.5 then camera.zoom = 0.5 end
    end
    
    -- Update camera to follow player
    camera.target_x = player.x + player.size / 2
    camera.target_y = player.y + player.size / 2
    
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
        
        -- Keep within 100 pixels of origin (like C demo)
        local max_distance = 100
        if enemy.x < enemy.origin_x - max_distance then enemy.x = enemy.origin_x - max_distance end
        if enemy.x > enemy.origin_x + max_distance then enemy.x = enemy.origin_x + max_distance end
        if enemy.y < enemy.origin_y - max_distance then enemy.y = enemy.origin_y - max_distance end
        if enemy.y > enemy.origin_y + max_distance then enemy.y = enemy.origin_y + max_distance end
        
        -- Keep enemies in bounds
        if enemy.x < 0 or enemy.x > 800 - enemy.size then
            enemy.dir_x = -enemy.dir_x
        end
        if enemy.y < 0 or enemy.y > 600 - enemy.size then
            enemy.dir_y = -enemy.dir_y
        end
        
        -- Check collision with player using Leo collision API
        if leo_check_collision_recs then
            local player_rect = {player.x, player.y, player.size, player.size}
            local enemy_rect = {enemy.x, enemy.y, enemy.size, enemy.size}
            if leo_check_collision_recs(player_rect[1], player_rect[2], player_rect[3], player_rect[4],
                                       enemy_rect[1], enemy_rect[2], enemy_rect[3], enemy_rect[4]) then
                player.alive = false
                print("Collision detected with Leo API at player:", player.x, player.y, "enemy:", enemy.x, enemy.y)
            end
        else
            -- Fallback to manual collision
            local dx = enemy.x - player.x
            local dy = enemy.y - player.y
            if dx*dx + dy*dy < (enemy.size + player.size)*(enemy.size + player.size)/4 then
                player.alive = false
                print("Collision detected with manual method!")
            end
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

-- Helper function to safely convert to integer
local function safe_int(value)
    if type(value) ~= "number" or value ~= value then -- Check for NaN
        return 0
    end
    return math.floor(value + 0.5) -- Round to nearest integer
end

-- Render game
function leo_render()
    -- Clear background to dark blue
    leo_clear_background(32, 32, 64, 255)
    
    -- Begin camera mode for world rendering
    if leo_begin_mode2d then
        leo_begin_mode2d(camera)
    end
    
    -- Draw tiled map if available
    if tiled_map and leo_tiled_find_tile_layer then
        local dirt_layer = leo_tiled_find_tile_layer(tiled_map, "dirt-layer")
        local tree_layer = leo_tiled_find_tile_layer(tiled_map, "tree-layer")
        
        if dirt_layer and dirt_texture then
            -- Simple tile rendering (no culling for now)
            local width, height = leo_tiled_tile_layer_get_size(dirt_layer)
            for y = 0, height - 1 do
                for x = 0, width - 1 do
                    local gid = leo_tiled_get_gid(dirt_layer, x, y)
                    if gid == 1 then -- Dirt tile
                        leo_draw_texture_rec(dirt_texture, 0, 0, 32, 32, x * 32, y * 32, 255, 255, 255, 255)
                    end
                end
            end
        end
        
        if tree_layer and tree_texture then
            local width, height = leo_tiled_tile_layer_get_size(tree_layer)
            for y = 0, height - 1 do
                for x = 0, width - 1 do
                    local gid = leo_tiled_get_gid(tree_layer, x, y)
                    if gid == 2 then -- Tree tile
                        leo_draw_texture_rec(tree_texture, 0, 0, 32, 32, x * 32, y * 32, 255, 255, 255, 255)
                    end
                end
            end
        end
    end
    
    -- Skip particles for now to isolate issue
    -- for _, particle in ipairs(particles) do
    --     local flash = 0.5 + 0.5 * math.sin(particle.flash_timer * 3)
    --     local alpha = safe_int(180 * flash)
    --     leo_draw_circle(safe_int(particle.x), safe_int(particle.y), 1.5, 255, 140, 0, alpha)
    -- end
    
    -- Draw player
    if player.alive then
        if textures.hero and leo_draw_texture_rec then
            -- Draw with texture
            leo_draw_texture_rec(textures.hero, 0, 0, 32, 32, player.x, player.y, 255, 255, 255, 255)
        else
            -- Fallback to rectangle
            leo_draw_rectangle(safe_int(player.x), safe_int(player.y), player.size, player.size, 0, 255, 0, 255)
        end
    else
        -- Draw dead player in red
        leo_draw_rectangle(safe_int(player.x), safe_int(player.y), player.size, player.size, 255, 0, 0, 255)
    end
    
    -- Draw enemies
    for _, enemy in ipairs(enemies) do
        if textures.enemy and leo_draw_texture_rec then
            -- Draw with texture
            leo_draw_texture_rec(textures.enemy, 0, 0, 32, 32, enemy.x, enemy.y, 255, 255, 255, 255)
        else
            -- Fallback to rectangle
            leo_draw_rectangle(safe_int(enemy.x), safe_int(enemy.y), enemy.size, enemy.size, 255, 0, 255, 255)
        end
    end
    
    -- End camera mode
    if leo_end_mode2d then
        leo_end_mode2d()
    end
    
    -- Draw UI text (not affected by camera)
    if leo_draw_text then
        -- Instructions
        leo_draw_text("WASD/Arrows: Move", 10, 10, 16, 255, 255, 255, 255)
        leo_draw_text("+/-: Zoom", 10, 30, 16, 255, 255, 255, 255)
        leo_draw_text("ESC: Quit", 10, 50, 16, 255, 255, 255, 255)
        
        -- Camera info
        local zoom_text = string.format("Zoom: %.1f", camera.zoom)
        leo_draw_text(zoom_text, 10, 80, 16, 255, 255, 0, 255)
        
        if not player.alive then
            leo_draw_text("YOU DIED! Press R to respawn", 10, 110, 20, 255, 0, 0, 255)
        end
        
        -- FPS counter
        if leo_draw_fps then
            leo_draw_fps(10, 550)
        end
    else
        -- Fallback to rectangles
        if not player.alive then
            leo_draw_rectangle(350, 250, 100, 20, 255, 0, 0, 255)
        end
        leo_draw_rectangle(10, 10, 200, 60, 0, 0, 0, 128)
    end
end

-- Cleanup
function leo_exit()
    print("Leo Lua Game exiting")
    
    -- Cleanup textures
    if textures.hero and leo_image_unload then
        leo_image_unload(textures.hero)
    end
    if textures.enemy and leo_image_unload then
        leo_image_unload(textures.enemy)
    end
    if dirt_texture and leo_image_unload then
        leo_image_unload(dirt_texture)
    end
    if tree_texture and leo_image_unload then
        leo_image_unload(tree_texture)
    end
    
    -- Cleanup tiled map
    if tiled_map and leo_tiled_free then
        leo_tiled_free(tiled_map)
    end
end
