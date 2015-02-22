--[[
    This file is part of Ice Lua Components.

    Ice Lua Components is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ice Lua Components is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with Ice Lua Components.  If not, see <http://www.gnu.org/licenses/>.
]]
FONT_DEFAULT = "OpenSans-Regular"
DIR_PKG_TTF = "pkg/base/ttf"
-- Some libraries
dofile("pkg/iceball/lib/font.lua")
-- dofile("pkg/iceball/lib/sdlkey.lua") --SDL2 this

-- Some hooks
-- function client.hook_key(key, state, modif, uni)
	-- if not state then
		-- if key == SDLK_l then
			-- client.mk_sys_execv("-s", "20737", "pkg/base", arg_closure(argv))
		-- elseif key == SDLK_c then
			-- client.mk_sys_execv("-s", "0", "pkg/iceball/config")
		-- elseif key == SDLK_ESCAPE then
			-- client.hook_tick = nil
		-- elseif key >= SDLK_1 and key <= SDLK_9 then
			-- local idx = (key - SDLK_1) + 1
			-- if idx <= #server_list then
				-- local sv = server_list[idx]
				-- client.mk_sys_execv("-c", sv.address, sv.port, arg_closure(argv))
			-- end
		-- elseif key == SDLK_r then
			-- master_http = http_new {url = MASTER_URL}
		-- end
	-- end
-- end

--render pre-load
-- local screen_width, screen_height = client.screen_get_dims()

-- local font = font_dejavu_bold[18]
-- local ch = font.iheight
-- local text_offset = ch+ch --cha cha cha! \o/

-- local img_row_bkg_width = screen_width - 2*text_offset
-- local img_row_bkg = common.img_new(img_row_bkg_width, ch + 2)
-- common.img_fill(img_row_bkg, 0x99111111)
-- local img_row_bkg_transparent = common.img_new(img_row_bkg_width, ch + 2)
-- common.img_fill(img_row_bkg_transparent, 0x22111111)

local img_splash = common.img_load("pkg/iceball/gfx/man.png", "png")
-- local img_splash_width, img_splash_height
-- local img_splash_width, img_splash_height_scaled
-- local splash_x, splash_y

-- local splashtweenprogress_scale = 0.9
-- local splashtweenprogress_y = 1.0

-- local superdooper = common.font_ttf_load("propaganda", 52)
-- local img = client.font_render_to_texture(superdooper, "This man marches for our freedom.", 0x11FF11)
-- local img2 = client.font_render_to_texture(superdooper, "For our glory. Join the green army!", 0x11FF11)
-- client.font_render_text(70, 300, "THIS IS A FONT API TEST TEXT", 0x11FF11, 16, FONT_DEFAULT)
client.map_fog_set(16, 136, 189, 100)
glob_font = common.font_ttf_load(DIR_PKG_TTF.."/"..FONT_DEFAULT..".ttf", 16)
print(glob_font)
function client.hook_render()
	-- font.render(0, ch*0, "Test text", 0xFFEEEEEE)
	-- print(superdooper)

	-- client.img_blit(img_splash, 0, -125, 1816/1.41875, 2043/1.41875,  0, 0, 0xFFFFFFFF,1/1.41875,1/1.41875)
	-- client.img_blit(img, 50, 0)
	-- --client.img_blit(superdooper, 0, 0)
	-- client.img_blit(img2, 70, 720)
	client.font_render_text(70, 300, "THIS IS A FONT API TEST TEXT", 0xd20011, 16, FONT_DEFAULT)
end

function client.hook_tick(sec_current, sec_delta)
	return 0.01
end
