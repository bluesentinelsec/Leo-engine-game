function leo_init()
	math.randomseed(1) -- fixed seed = always same beautiful pattern
	time = 0

	-- Precomputed sin/cos table (512 entries = 0..511)
	sin = {}
	cos = {}
	for i = 0, 511 do
		local a = i * math.pi * 2 / 512
		sin[i] = math.sin(a)
		cos[i] = math.cos(a)
	end

	-- 600 rotating 3D stars
	stars = {}
	for i = 1, 600 do
		local a = math.random() * math.pi * 2
		local dist = math.random() ^ 0.5 * 1200
		stars[i] = {
			x = math.cos(a) * dist,
			y = math.random() * 800 - 400,
			z = math.random() * 1600,
		}
	end
end

function leo_update(dt)
	time = time + dt
end

function leo_render()
	local t = time
	local W, H = 1280, 740
	local cx, cy = 640, 370

	----------------------------------------------------------------
	-- 1. Animated plasma background
	----------------------------------------------------------------
	for y = 0, H - 1, 2 do -- step 2 = faster + still looks great
		for x = 0, W - 1, 2 do
			local u = x * 0.02
			local v = y * 0.02
			local p = sin[math.floor((x + t * 320) % 512)]
				+ sin[math.floor((y * 0.7 + t * 280) % 512)]
				+ sin[math.floor((x + y + t * 400) % 512 * 0.7)]
				+ sin[math.floor((math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2) * 0.03 + t * 600) % 512)]

			local c = (p * 40 + 128)
			local r = sin[math.floor((c + t * 100) % 512)] * 127 + 128
			local g = sin[math.floor((c + t * 140) % 512)] * 127 + 128
			local b = sin[math.floor((c + t * 180) % 512)] * 127 + 128

			leo_draw_pixel(x, y, r, g, b)
			leo_draw_pixel(x + 1, y, r, g, b)
			leo_draw_pixel(x, y + 1, r, g, b)
			leo_draw_pixel(x + 1, y + 1, r, g, b)
		end
	end

	----------------------------------------------------------------
	-- 2. Infinite rotating tunnel
	----------------------------------------------------------------
	local tunnel_time = t * 3
	for i = 0, 240 do
		local depth = i * 8
		local radius = 80 + sin[math.floor((t * 200 + i * 30) % 512)] * 40
		local angle_step = 0.2
		for a = 0, 6.28, angle_step do
			local wx = math.cos(a + tunnel_time) * radius
			local wy = math.sin(a + tunnel_time) * radius
			local screen_z = 400 / (depth + 100)
			local px = cx + wx * screen_z
			local py = cy + wy * screen_z * 0.6 -- slight squash

			local brightness = 255 * (1 - i / 300)
			local pulse = sin[math.floor((i * 15 + t * 500) % 512)] * 0.5 + 0.5
			local r = brightness * pulse
			local g = brightness * (1 - pulse * 0.5)
			local b = brightness * 0.8

			if px >= 0 and px < W and py >= 0 and py < H then
				leo_draw_pixel(px, py, r, g, b)
				leo_draw_pixel(px + 1, py, r * 0.7, g * 0.7, b * 0.7)
				leo_draw_pixel(px, py + 1, r * 0.7, g * 0.7, b * 0.7)
			end
		end
	end

	----------------------------------------------------------------
	-- 3. 3D rotating starfield
	----------------------------------------------------------------
	local rot = t * 0.7
	local cr = cos[math.floor((rot * 512 / (math.pi * 2)) % 512)]
	local sr = sin[math.floor((rot * 512 / (math.pi * 2)) % 512)]

	for _, s in ipairs(stars) do
		-- rotate around Y axis
		local rx = s.x * cr - s.z * sr
		local rz = s.x * sr + s.z * cr
		local z = rz + 1200

		if z > 50 then
			local scale = 800 / z
			local px = cx + rx * scale
			local py = cy + s.y * scale

			local bright = 255 * (2000 - z) / 2000
			if bright > 20 and px >= 0 and px < W and py >= 0 and py < H then
				leo_draw_pixel(px, py, bright, bright * 0.9, bright * 1.2)
				if bright > 120 then
					leo_draw_pixel(px - 1, py, bright * 0.6, bright * 0.6, bright * 0.8)
					leo_draw_pixel(px, py - 1, bright * 0.6, bright * 0.6, bright * 0.8)
				end
			end
		end
	end

	----------------------------------------------------------------
	-- 4. Big pulsing scroller text (pure pixel blobs)
	----------------------------------------------------------------
	local text = "  LEOPIXEL 2025   PURE LEO ENGINE   NO INPUT   NO LOVE   JUST PIXELS   "
	local pos = (t * 60) % (#text * 24)
	local scale = 5 + sin[math.floor((t * 300) % 512)] * 2

	for i = 1, #text do
		local char_x = (i * 24 - pos) % (W + 200) - 100
		if char_x > -100 and char_x < W + 100 then
			local hue = (t * 80 + i * 25) % 360
			local r = 128 + 127 * sin[math.floor((hue * 1.42) % 512)]
			local g = 128 + 127 * sin[math.floor(((hue + 120) * 1.42) % 512)]
			local b = 128 + 127 * sin[math.floor(((hue + 240) * 1.42) % 512)]
			local cy_text = 540 + sin[math.floor((t * 150 + i * 40) % 512)] * 30

			-- draw each "letter" as a 9×11 blob
			for dy = -5, 5 do
				for dx = -4, 4 do
					local intensity = 1 - math.abs(dx) / 5 - math.abs(dy) / 6
					if intensity > 0.3 then
						local px = char_x + dx * scale
						local py = cy_text + dy * scale
						leo_draw_pixel(px, py, r * intensity, g * intensity, b * intensity, 255)
					end
				end
			end
		end
	end
end

function leo_exit() end
