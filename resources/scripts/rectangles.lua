local time_alive = 0

function leo_init()
	if leo_set_target_fps then
		leo_set_target_fps(60)
	end
	return true
end

function leo_update(dt)
	time_alive = time_alive + dt

	if leo_is_key_pressed and leo_is_key_pressed(leo_KEY_ESCAPE) then
		leo_quit()
	end
end

function leo_render()
	local screen_w = leo_get_screen_width and leo_get_screen_width() or 1280
	local screen_h = leo_get_screen_height and leo_get_screen_height() or 720
	local center_x = screen_w / 2
	local center_y = screen_h / 2

	leo_clear_background(18, 18, 26, 255)

	-- Filled rectangle pulsing in size/alpha
	local fill_w = 220 + math.sin(time_alive * 2.0) * 80
	local fill_h = 140 + math.cos(time_alive * 1.4) * 60
	local fill_alpha = 160 + math.floor((math.sin(time_alive * 3.0) * 0.5 + 0.5) * 95)
	leo_draw_rectangle(
		math.floor(center_x - fill_w / 2),
		math.floor(center_y - fill_h / 2),
		math.floor(fill_w),
		math.floor(fill_h),
		70,
		190,
		255,
		fill_alpha
	)

	-- Outline rectangle orbiting around the filled one
	local orbit_radius = math.min(screen_w, screen_h) / 3
	local outline_x = center_x + math.cos(time_alive) * orbit_radius * 0.6
	local outline_y = center_y + math.sin(time_alive * 1.3) * orbit_radius * 0.4
	local outline_w = 120 + math.sin(time_alive * 2.2) * 40
	local outline_h = 80 + math.cos(time_alive * 2.5) * 30
	leo_draw_rectangle_lines(
		math.floor(outline_x - outline_w / 2),
		math.floor(outline_y - outline_h / 2),
		math.floor(outline_w),
		math.floor(outline_h),
		255,
		230,
		80,
		255
	)

	-- Small static legend in the corner
	leo_draw_rectangle(30, 30, 90, 50, 60, 160, 90, 255)
	leo_draw_rectangle_lines(30, 30, 90, 50, 255, 255, 255, 255)

	if leo_draw_text then
		leo_draw_text("Pulsing fill (center)", 30, 90, 18, 210, 230, 255, 255)
		leo_draw_text("Orbiting outline (yellow)", 30, 115, 18, 255, 230, 80, 255)
		leo_draw_text("Press ESC to quit", 30, screen_h - 36, 16, 180, 180, 180, 255)
	end
end

function leo_exit() end
