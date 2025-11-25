-- Demonstration of leo_draw_line(x1, y1, x2, y2, r, g, b[, a])
-- Shows horizontal, vertical, and diagonal lines with and without explicit alpha.

local lines = {}

function leo_init()
    local cx, cy = 640, 360
    lines = {
        { x1 = 40,  y1 = 40,  x2 = 400,  y2 = 40,  r = 255, g = 80,  b = 80,  a = 255 }, -- horizontal
        { x1 = 40,  y1 = 80,  x2 = 40,   y2 = 320, r = 80,  g = 200, b = 255             }, -- vertical with default alpha
        { x1 = cx - 220, y1 = cy - 160, x2 = cx + 220, y2 = cy + 160, r = 255, g = 220, b = 60,  a = 255 }, -- main diagonal
        { x1 = cx + 220, y1 = cy - 160, x2 = cx - 220, y2 = cy + 160, r = 120, g = 255, b = 140, a = 180 }, -- cross with semi-transparency
        { x1 = 100, y1 = 680, x2 = 1180, y2 = 600, r = 200, g = 120, b = 255, a = 255 }, -- shallow slope
        { x1 = 1180, y1 = 680, x2 = 100,  y2 = 600, r = 255, g = 255, b = 255, a = 120 }  -- reverse slope, semi-transparent
    }
    return true
end


function leo_update(dt)
    if leo_is_key_pressed and leo_is_key_pressed(leo_KEY_ESCAPE) then
        leo_quit()
    end
end


function leo_render()
    leo_clear_background(18, 18, 24, 255)

    for _, line in ipairs(lines) do
        if line.a then
            leo_draw_line(line.x1, line.y1, line.x2, line.y2, line.r, line.g, line.b, line.a)
        else
            leo_draw_line(line.x1, line.y1, line.x2, line.y2, line.r, line.g, line.b)
        end
    end

    if leo_draw_text then
        leo_draw_text("Line drawing demo", 24, 24, 20, 255, 255, 255, 255)
        leo_draw_text("Tests default alpha (blue vertical) and explicit alpha (green/white lines)", 24, 48, 16, 200, 200, 200, 255)
    end
end


function leo_exit()
end
