-- Demonstration of leo_draw_circle(x, y, radius, r, g, b[, a])
-- Shows outlined circles and filled circles with explicit/default alpha plus transparency layering.

local circles = {}
local filled = {}
local elapsed_time = 0

local function pulse_alpha(entry)
	local base = entry.a or 255
	if not entry.pulse then
		return base
	end

	local amp = entry.pulse_amp or 80 -- how far to swing
	local speed = entry.pulse_speed or 2.0 -- radians/sec
	local bias = entry.pulse_bias or 0 -- shift up/down
	local t = (leo_get_time and leo_get_time()) or elapsed_time
	local wave = math.sin(t * speed + (entry.pulse_phase or 0))
	local alpha = base + wave * amp + bias

	local min_a = entry.pulse_min or 0
	local max_a = entry.pulse_max or 255
	if alpha < min_a then
		alpha = min_a
	end
	if alpha > max_a then
		alpha = max_a
	end
	return alpha
end

function leo_init()
	circles = {
		{ x = 220, y = 200, radius = 70, r = 255, g = 90, b = 90, a = 255 }, -- opaque red outline
		{ x = 460, y = 200, radius = 70, r = 80, g = 200, b = 255 }, -- default alpha (should be fully opaque)
		{ x = 700, y = 200, radius = 70, r = 255, g = 220, b = 60, a = 180, pulse = true, pulse_amp = 50 }, -- pulsing yellow
		{
			x = 940,
			y = 200,
			radius = 70,
			r = 255,
			g = 255,
			b = 255,
			a = 80,
			pulse = true,
			pulse_amp = 70,
			pulse_min = 30,
			pulse_max = 180,
		}, -- pulsing faint white
		-- Overlapping rings to highlight alpha blending
		{
			x = 400,
			y = 500,
			radius = 120,
			r = 180,
			g = 120,
			b = 255,
			a = 200,
			pulse = true,
			pulse_amp = 40,
			pulse_speed = 1.4,
		},
		{ x = 520, y = 500, radius = 120, r = 120, g = 255, b = 180, a = 160 },
		{
			x = 640,
			y = 500,
			radius = 120,
			r = 255,
			g = 150,
			b = 80,
			a = 120,
			pulse = true,
			pulse_amp = 35,
			pulse_speed = 2.2,
			pulse_phase = 1.0,
		},
	}
	filled = {
		{ x = 220, y = 360, radius = 60, r = 255, g = 120, b = 120, a = 255 }, -- opaque red fill
		{ x = 460, y = 360, radius = 60, r = 90, g = 210, b = 255 }, -- default alpha
		{ x = 700, y = 360, radius = 60, r = 255, g = 220, b = 60, a = 160, pulse = true, pulse_amp = 60 },
		{
			x = 940,
			y = 360,
			radius = 60,
			r = 255,
			g = 255,
			b = 255,
			a = 100,
			pulse = true,
			pulse_amp = 80,
			pulse_min = 40,
			pulse_max = 200,
		},
		-- Overlapping fills to show blended areas
		{
			x = 460,
			y = 520,
			radius = 110,
			r = 180,
			g = 120,
			b = 255,
			a = 140,
			pulse = true,
			pulse_amp = 50,
			pulse_speed = 1.6,
		},
		{ x = 600, y = 520, radius = 110, r = 120, g = 255, b = 180, a = 140 },
		{
			x = 740,
			y = 520,
			radius = 110,
			r = 255,
			g = 150,
			b = 80,
			a = 140,
			pulse = true,
			pulse_amp = 45,
			pulse_speed = 2.4,
			pulse_phase = 0.7,
		},
	}
	return true
end

function leo_update(dt)
	elapsed_time = elapsed_time + (dt or 0)

	if leo_is_key_pressed and leo_is_key_pressed(leo_KEY_ESCAPE) then
		leo_quit()
	end
end

function leo_render()
	leo_clear_background(18, 18, 24, 255)

	for _, c in ipairs(filled) do
		local alpha = pulse_alpha(c)
		if alpha ~= 255 then
			leo_draw_circle_filled(c.x, c.y, c.radius, c.r, c.g, c.b, alpha)
		else
			leo_draw_circle_filled(c.x, c.y, c.radius, c.r, c.g, c.b)
		end
	end

	for _, c in ipairs(circles) do
		local alpha = pulse_alpha(c)
		if alpha ~= 255 then
			leo_draw_circle(c.x, c.y, c.radius, c.r, c.g, c.b, alpha)
		else
			leo_draw_circle(c.x, c.y, c.radius, c.r, c.g, c.b)
		end
	end

	if leo_draw_text then
		leo_draw_text("Circle demo (outline + filled)", 24, 24, 20, 255, 255, 255, 255)
		leo_draw_text(
			"Top row: outlines | Middle: fills | Bottom: overlapping outlines/fills with pulsing alpha",
			24,
			48,
			16,
			200,
			200,
			200,
			255
		)
	end
end

function leo_exit() end
