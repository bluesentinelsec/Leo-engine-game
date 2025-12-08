
sprite = ""
max_rotation = 360
current_rotation = 0


function leo_init() 
    sprite = leo_image_load("images/character_64x64.png")
end

function leo_update(dt) 
    current_rotation = current_rotation + 100 * dt
end

function leo_render()
    if current_rotation >= max_rotation then
        current_rotation = 0
    end
    leo_draw_texture_rec(sprite, 0, 0, 64, 64, 32, 50)
    leo_draw_texture_pro(sprite, 0, 0, 64, 64, 32, 128, 64, 64, 32, 32, current_rotation, 128, 255, 128, 255)
    leo_draw_text("Rotation: " .. math.floor(current_rotation), 0, 32, 32, 255, 255, 255, 255)
end

function leo_exit() end
