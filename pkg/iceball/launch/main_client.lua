--[[
Copyright (c) 2014 Team Sparkle

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

-- Master server to use.
MASTER_URL = "http://magicannon.com:27790/master.json"

-- Time in seconds between auto-updates, or nil to disable
AUTO_REFRESH_RATE = nil

-- Some arguments...
argv = {...}

-- Connect to master server
dofile("pkg/iceball/lib/http.lua")
server_list = true
master_http = http_new {url = MASTER_URL}
if not master_http then
	server_list = false
end

-- A creative hack to make this whole thing work.
function arg_closure(arg_array, offset)
	offset = offset or 1

	if #arg_array == 0 then
		return
	elseif offset == #arg_array then
		return arg_array[offset]
	else
		return arg_array[offset], arg_closure(arg_array, offset+1)
	end
end

-- Some libraries
dofile("pkg/iceball/lib/font.lua")
dofile("pkg/iceball/lib/sdlkey.lua")

-- Some hooks
function client.hook_key(key, state, modif, uni)
	if not state then
		if key == SDLK_l then
			client.mk_sys_execv("-s", "20737", "pkg/base", arg_closure(argv))
		elseif key == SDLK_c then
			client.mk_sys_execv("-s", "0", "pkg/iceball/config")
		elseif key == SDLK_ESCAPE then
			client.hook_tick = nil
		elseif key >= SDLK_1 and key <= SDLK_9 then
			local idx = (key - SDLK_1) + 1
			if idx <= #server_list then
				local sv = server_list[idx]
				client.mk_sys_execv("-c", sv.address, sv.port, arg_closure(argv))
			end
		elseif key == SDLK_r then
			master_http = http_new {url = MASTER_URL}
		end
	end
end

--render pre-load
local screen_width, screen_height = client.screen_get_dims()

local font = font_dejavu_bold[18]
local ch = font.iheight
local text_offset = ch+ch --cha cha cha! \o/

local img_row_bkg_width = screen_width - 2*text_offset
local img_row_bkg = common.img_new(img_row_bkg_width, ch + 2)
common.img_fill(img_row_bkg, 0x99111111)
local img_row_bkg_transparent = common.img_new(img_row_bkg_width, ch + 2)
common.img_fill(img_row_bkg_transparent, 0x22111111)

local img_splash, img_splash_width, img_splash_height = common.img_load("pkg/iceball/gfx/splash_logo.png", "png")
local img_splash_width, img_splash_height_scaled
local splash_x, splash_y

local splashtweenprogress_scale = 0.9
local splashtweenprogress_y = 1.0

client.map_fog_set(16, 136, 189, 100)
function client.hook_render()
	--splash sequence
	if not img_splash_width then
		img_splash_width, img_splash_height = common.img_get_dims(img_splash)
	end
	
	if splashtweenprogress_scale > 0.25 then
		if splashtweenprogress_scale > 0.85 then
			splashtweenprogress_scale = splashtweenprogress_scale - 0.001 --would be nice to do this with frame delta time
		elseif splashtweenprogress_scale < 0.5 then
			splashtweenprogress_scale = splashtweenprogress_scale - 0.0112
		else
			splashtweenprogress_scale = splashtweenprogress_scale - 0.068
		end
	end
	if splashtweenprogress_y < 2.0 and  splashtweenprogress_scale < 0.85 then
		splashtweenprogress_y = splashtweenprogress_y + 0.1
	end
	img_splash_width_scaled = img_splash_width*splashtweenprogress_scale
	img_splash_height_scaled = img_splash_height*splashtweenprogress_scale

	splash_x = (screen_width/2) - (img_splash_width_scaled/2)
	splash_y = (screen_height/(2/splashtweenprogress_y)) - img_splash_height_scaled
	client.img_blit(img_splash, splash_x, splash_y, img_splash_width_scaled, img_splash_height_scaled, 0, 0, 0xFFFFFFFF, splashtweenprogress_scale, splashtweenprogress_scale)
	--splash sequence end
	
	if splashtweenprogress_scale <= 0.5 then --don't draw the rest until the splash finishes
	
	
	font.render(text_offset, ch*0, "Press L for a local server on port 20737", 0xFFEEEEEE)
	font.render(text_offset, ch*1, "Press Escape to quit", 0xFFEEEEEE)
	font.render(text_offset, ch*2, "Press C to change your settings", 0xFFEEEEEE)
	font.render(text_offset, ch*3, "Press R to update the server list", 0xFFEEEEEE)
	font.render(text_offset, ch*4, "Press a number to join a server", 0xFFEEEEEE)
	font.render(text_offset, ch*6, "Server list:", 0xFFEEEEEE)

	local i
	if server_list == true then
		font.render(text_offset, ch*7, "Fetching...", 0xFFEEEEEE)
	elseif server_list == nil then
		font.render(text_offset, ch*7, "Failed to fetch the server list.", 0xFFEEEEEE)
	else
		for i=1,#server_list do
			client.img_blit(img_row_bkg, text_offset-2, (ch+4)*(8+i-1) - 1)
		
			local sv = server_list[i]
			font.render(text_offset, (ch+4)*(8+i-1), i..": "..sv.name
				.." - "..sv.players_current.."/"..sv.players_max
				.." - "..sv.mode
				.." - "..sv.map, 0xFFEEEEEE)
			
		end
--		common.img_fill(img_row_bkg, 0x22111111)
		for i=#server_list+1,9 do
			client.img_blit(img_row_bkg_transparent, text_offset-2, (ch+4)*(8+i-1) - 1)
		end
		--common.img_fill(img_row_bkg, 0x99111111)
	end
	
	end
end

server_refresh = 0
function client.hook_tick(sec_current, sec_delta)
	-- Fetch the master server list if possible.
	if master_http then
		local status = master_http.update()
		if status == nil then
			master_http = nil
			server_refresh = sec_current
			server_list = nil
		elseif status ~= true then
			print(status)
			server_list = common.json_parse(status)
			server_list = server_list and server_list.servers
			master_http = nil
			server_refresh = sec_current
		end
	elseif AUTO_REFRESH_RATE and server_refresh + AUTO_REFRESH_RATE < sec_current then
		master_http = http_new {url = MASTER_URL}
	end
	
	return 0.01
end

