
sprite = ""

function leo_init() 
    sprite = leo_image_load("images/character_64x64.png")
end

function leo_update(dt) end

function leo_render()
    leo_draw_texture_rec(sprite, 0, 0, 64, 64, 30, 50)
end

function leo_exit() end
