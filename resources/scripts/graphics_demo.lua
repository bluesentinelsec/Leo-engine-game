-- Leo Engine Lua Performance Test
-- Simple graphics test using Leo graphics API

-- Game state
local player = {
	x = 640,
	y = 360,
	speed = 400,
}

local balls = {}
local grid_offset = 0
local frame_time = 0
local last_time = 0

-- Initialize game
function leo_init()
	print("Leo Lua Performance Test initialized")

	-- Initialize bouncing balls
	math.randomseed(os.time())
	for i = 1, 50 do
		table.insert(balls, {
			x = math.random(0, 1280),
			y = math.random(0, 720),
			vel_x = (math.random() - 0.5) * 400, -- -200 to 200
			vel_y = (math.random() - 0.5) * 400,
			radius = 10 + math.random(0, 20), -- 10-30 radius
			r = 128 + math.random(0, 127), -- 128-255
			g = 128 + math.random(0, 127),
			b = 128 + math.random(0, 127),
		})
	end

	return true
end

-- Update game logic
function leo_update(dt)
	-- Handle quit
	if leo_is_key_pressed and leo_is_key_pressed(leo_KEY_ESCAPE) then
		leo_quit()
		return
	end

	-- Update frame timing
	local current_time = os.clock() * 1000 -- Convert to milliseconds
	if last_time > 0 then
		frame_time = current_time - last_time
	end
	last_time = current_time

	-- Update player movement
	local dx, dy = 0, 0
	if leo_is_key_down then
		if leo_is_key_down(leo_KEY_A) or leo_is_key_down(leo_KEY_LEFT) then
			dx = -1
		end
		if leo_is_key_down(leo_KEY_D) or leo_is_key_down(leo_KEY_RIGHT) then
			dx = 1
		end
		if leo_is_key_down(leo_KEY_W) or leo_is_key_down(leo_KEY_UP) then
			dy = -1
		end
		if leo_is_key_down(leo_KEY_S) or leo_is_key_down(leo_KEY_DOWN) then
			dy = 1
		end
	end

	player.x = player.x + dx * player.speed * dt
	player.y = player.y + dy * player.speed * dt

	-- Keep player on screen
	if player.x < 20 then
		player.x = 20
	end
	if player.x > 1260 then
		player.x = 1260
	end
	if player.y < 20 then
		player.y = 20
	end
	if player.y > 700 then
		player.y = 700
	end

	-- Update bouncing balls
	for _, ball in ipairs(balls) do
		ball.x = ball.x + ball.vel_x * dt
		ball.y = ball.y + ball.vel_y * dt

		-- Bounce off walls
		if ball.x <= ball.radius or ball.x >= 1280 - ball.radius then
			ball.vel_x = -ball.vel_x
			if ball.x <= ball.radius then
				ball.x = ball.radius
			end
			if ball.x >= 1280 - ball.radius then
				ball.x = 1280 - ball.radius
			end
		end
		if ball.y <= ball.radius or ball.y >= 720 - ball.radius then
			ball.vel_y = -ball.vel_y
			if ball.y <= ball.radius then
				ball.y = ball.radius
			end
			if ball.y >= 720 - ball.radius then
				ball.y = 720 - ball.radius
			end
		end
	end

	-- Animate background grid
	grid_offset = grid_offset + 50 * dt
	if grid_offset >= 50 then
		grid_offset = grid_offset - 50
	end
end

-- Render game
function leo_render()
	-- Clear to dark blue background
	leo_clear_background(20, 20, 40, 255)

	-- Draw animated background grid
	for x = math.floor(-grid_offset), 1280, 50 do
		leo_draw_line(x, 0, x, 720, 40, 40, 80, 255)
	end
	for y = math.floor(-grid_offset), 720, 50 do
		leo_draw_line(0, y, 1280, y, 40, 40, 80, 255)
	end

	-- Draw bouncing balls
	for _, ball in ipairs(balls) do
		leo_draw_circle_filled(math.floor(ball.x), math.floor(ball.y), ball.radius, ball.r, ball.g, ball.b, 255)
		leo_draw_circle(math.floor(ball.x), math.floor(ball.y), ball.radius, 255, 255, 255, 255)
	end

	-- Draw player as bright square with outline
	leo_draw_rectangle(math.floor(player.x - 20), math.floor(player.y - 20), 40, 40, 255, 255, 255, 255)
	leo_draw_rectangle_lines(math.floor(player.x - 20), math.floor(player.y - 20), 40, 40, 255, 255, 0, 255)

	-- Draw player trail effect
	for i = 1, 5 do
		local alpha = math.floor(50 / i)
		leo_draw_rectangle(
			math.floor(player.x - 15 - i * 2),
			math.floor(player.y - 15 - i * 2),
			30 + i * 4,
			30 + i * 4,
			255,
			255,
			0,
			alpha
		)
	end

	-- Draw UI text
	if leo_draw_text then
		-- Performance info with color coding
		local fps = 1000 / frame_time
		local fps_text = string.format("Frame: %.2fms (%.1f FPS)", frame_time, fps)
		local fps_r = frame_time > 20 and 255 or 0
		local fps_g = frame_time > 20 and 0 or 255
		leo_draw_text(fps_text, 20, 60, 16, fps_r, fps_g, 0, 255)

		leo_draw_text("PERFORMANCE TEST - Use WASD to move", 20, 140, 20, 255, 255, 0, 255)
		leo_draw_text("Watch for smooth movement and stable FPS", 20, 170, 16, 255, 255, 255, 255)
		leo_draw_text("Press ESC to quit", 20, 190, 16, 128, 128, 128, 255)
	end

	-- Draw FPS counter
	if leo_draw_fps then
		leo_draw_fps(20, 32)
	end
end

-- Cleanup
function leo_exit()
	print("Leo Lua Performance Test exiting")
end
