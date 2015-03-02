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

PKT_SNOW_DROP = network.sys_alloc_packet()

network.sys_handle_s2c(PKT_SNOW_DROP, "HHH", function (neth, cli, plr, sec_current, x, y, z, pkt)
	map_block_set(x,y,z,2,255,255,255)
end)

if USE_GLSL then
	shader_snow, result = shader_new{name="snow", vert=[=[
		// Vertex shader

		varying vec3 bcsrc; // Barycentric coordinates

		void main()
		{
			vec4 tc = vec4(gl_MultiTexCoord0.st, 0.0, 0.0);
			gl_Position = gl_ProjectionMatrix * (
				gl_ModelViewMatrix * (gl_Vertex - tc)
				+ (tc*2.0-1.0)*0.5*vec4(1.0, 0.8, 1.0, 1.0));

			bcsrc = vec3(
				tc.x-tc.y/2.0,
				tc.y,
				1.0-tc.x-tc.y/2.0);
		}
	]=], frag=[=[
		// Fragment shader

		varying vec3 bcsrc; // Barycentric coordinates

		void main()
		{
			const int steps = 4;
			int i;

			vec3 bc = bcsrc;

			gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
			for(i = 0; i < steps; i++)
			{
				// Ensure this is within the middle subtriangle
				if(max(max(bc.x, bc.y), bc.z) <= 0.5)
					return;

				// Rotate triangle such that Y is largest
				if(bc.z > bc.x && bc.z > bc.y) bc = bc.yzx;
				else if(bc.x > bc.y) bc = bc.zxy;

				// Convert to 2D
				bc = vec3(bc.x + bc.y/2.0, bc.y, 0.0);

				// Flip along Y + Scale
				bc -= 0.5;
				bc.y = -bc.y;
				bc *= 3.0;

				// Check if X notably out of range
				if(bc.x >= 0.5) { bc.x -= 0.5; bc *= 3.0; }
				else if(bc.x <= -0.5) { bc.x += 0.5; bc *= 3.0; }

				// Restore to centre
				bc += 0.5;

				// Convert to barycentric
				bc = vec3(
					bc.x-bc.y/2.0,
					bc.y,
					1.0-bc.x-bc.y/2.0);
			}

			discard;
		}
	]=]}
end

function snow_drop_part(x,z,t,bcast)
	local xlen,ylen,zlen
	xlen,ylen,zlen = common.map_get_dims()
	
	local ty = t[1+1]
	if ty > 0 and ty < ylen-1 then
		map_block_set(x,ty-1,z,2,255,255,255)
		if img_overview then
			common.img_pixel_set(img_overview,x,z,0xFFFFFFFF)
		end
		if bcast then
			bhealth_clear(x,ty-1,z,false)
			net_broadcast(nil, common.net_pack("BHHH",
				PKT_SNOW_DROP,x,ty-1,z))
		end
	end
end

--[[
function snow_drop(x,z,bcast)
	local tl = common.map_pillar_get(x-1,z)
	local tr = common.map_pillar_get(x+1,z)
	local tu = common.map_pillar_get(x,z-1)
	local td = common.map_pillar_get(x,z+1)
	local tc = common.map_pillar_get(x,z)
	
	if tl[1+1] > tc[1+1] then
		snow_drop_part(x-1,z,tl,bcast)
	elseif tr[1+1] > tc[1+1] then
		snow_drop_part(x+1,z,tr,bcast)
	elseif tu[1+1] > tc[1+1] then
		snow_drop_part(x,z-1,tu,bcast)
	elseif td[1+1] > tc[1+1] then
		snow_drop_part(x,z+1,td,bcast)
	else
		snow_drop_part(x,z,tc,bcast)
	end
end
]]
function snow_drop(x,z,bcast)
	local xlen,ylen,zlen
	xlen,ylen,zlen = common.map_get_dims()
	
	local t1 = math.floor(math.random()*2)
	local t2 = 2*math.floor(math.random()*2)-1
	local gx,gz
	gx = t2*t1
	gz = t2*(1-t1)
	
	local tc = common.map_pillar_get(x,z)
	local i
	for i=1,100 do
		local tn = common.map_pillar_get(x+gx,z+gz)
		if tn[1+1] >= ylen-1 or tn[1+1] < tc[1+1] then
			break
		else
			tc = tn
			x = x + gx
			z = z + gz
		end
	end
	snow_drop_part(x%xlen,z%zlen,tc,bcast)
end

function snow_init_pissdown(p_snow)
	local xlen,ylen,zlen
	xlen,ylen,zlen = common.map_get_dims()
	print("Snowing the map...",xlen,ylen,zlen)
	local x,y,z,i
	
	for z=0,zlen-1 do
	if z%8 == 0 then print(z) end
	for x=0,xlen-1 do
		if math.random() < p_snow then
			snow_drop(x,z,false)
		end
	end
	end
	print("Done!")
end

function snow_init_hook()
	do
		local function mpgnew(mpgold)
			return function(px,pz)
				local t = map_pillar_raw_unpack(mpgold(px,pz))
				local i
				local xlen,ylen,zlen
				xlen,ylen,zlen = common.map_get_dims()
				for i=0,ylen-1 do
					if t[i] and t[i][1] == 2 then
						t[i] = nil
					end
				end
				return map_pillar_raw_pack(t)
			end
		end
		
		local bicold = box_is_clear
		function box_is_clear(x1,y1,z1,x2,y2,z2,canwrap)
			local mpgold = common.map_pillar_get
			common.map_pillar_get = mpgnew(mpgold)
			local ret = bicold(x1,y1,z1,x2,y2,z2,canwrap)
			common.map_pillar_get = mpgold
			return ret
		end
		
		local trgold = trace_gap
		function trace_gap(x,y,z)
			local mpgold = common.map_pillar_get
			common.map_pillar_get = mpgnew(mpgold)
			local r1,r2
			r1,r2 = trgold(x,y,z)
			common.map_pillar_get = mpgold
			return r1,r2
		end
	end
end

if server then
	--snow_init_pissdown(0.1)
	snow_init_hook()
	local snow_lasttime = nil
	local snow_freq = 0.25
	local snow_oldtick = server.hook_tick
	function snow_tick(sec_current, sec_delta)
		snow_lasttime = snow_lasttime or sec_current
		local ct = 5
		local i
		
		-- hack to work around a bug
		if snow_lasttime - sec_current > 3 then
			snow_lasttime = sec_current
		end
		
		while sec_current >= snow_lasttime + snow_freq do
			local xlen,ylen,zlen
			xlen,ylen,zlen = common.map_get_dims()
			for i=1,5 do
				local x,z
				while true do
					x = math.floor(math.random()*xlen)
					z = math.floor(math.random()*zlen)
					local t = common.map_pillar_get(x,z)
					if t[1+1] < ylen-1 then break end
				end
				snow_drop(x,z,true)
			end
			snow_lasttime = snow_lasttime + snow_freq
			ct = ct - 1
			if ct <= 0 then
				snow_lasttime = sec_current
				break
			end
		end
		server.hook_tick = snow_oldtick
		local ret = server.hook_tick(sec_current, sec_delta)
		snow_oldtick = server.hook_tick
		server.hook_tick = snow_tick
		return ret
	end
	
	server.hook_tick = snow_tick
end

if client then
	snow_init_hook()
	
	local snowflakes = {
		sxp=0,szp=0,
		sx0=0,sz0=0,
		sx1=0,sz1=0,
		st=0,
	}
	local snow_flakecount = 1000
	local snow_flakedist = 60
	local snow_fallspeed = 13
	local snow_changetime = 1
	
	local xlen,ylen,zlen
	xlen,ylen,zlen = common.map_get_dims()
	
	do
		local i
		for i=1,snow_flakecount do
			local x,y,z
			x = math.random()*snow_flakedist*2
			y = math.random()*ylen
			z = math.random()*snow_flakedist*2
			snowflakes[#snowflakes+1] = {
				x=x,y=y,z=z,
			}
		end
	end
	
	local mdl_snow = common.model_new(1)
	local mdl_snow_bone
	mdl_snow, mdl_snow_bone = common.model_bone_new(mdl_snow, 1)
	local mdl_snow_name,mdl_snow_tab
	mdl_snow_name = "snow"
	mdl_snow_tab = {{radius=32, x=0,y=0,z=0, r=255,g=255,b=255}}
	common.model_bone_set(mdl_snow, mdl_snow_bone, mdl_snow_name, mdl_snow_tab)
	
	local snow_oldrender = client.hook_render
	function snow_render(...)
		local i
		local camx,camy,camz
		camx,camy,camz = client.camera_get_pos()

		local function draw_snow()
			local i
			if shader_snow then
				local l = {}
				shader_snow.push()
				for i=1,snow_flakecount do
					local px,py,pz
					px = snowflakes[i].x+snowflakes.sxp
					py = snowflakes[i].y
					pz = snowflakes[i].z+snowflakes.szp
					px = (px-camx+snow_flakedist)%(snow_flakedist*2)-snow_flakedist+camx
					pz = (pz-camz+snow_flakedist)%(snow_flakedist*2)-snow_flakedist+camz
					l[1+#l] = {px,py,pz,0.0,0.0}
					l[1+#l] = {px+1,py,pz,1.0,0.0}
					l[1+#l] = {px+0.5,py+1,pz,0.5,1.0}
				end
				snow_va = common.va_make(l, snow_va, "3v,2t")
				client.va_render_global(snow_va, 0, 0, 0, 0, 0, 0, 1)
				shader_snow.pop()
			else
				for i=1,snow_flakecount do
					local px,py,pz
					px = snowflakes[i].x+snowflakes.sxp
					py = snowflakes[i].y
					pz = snowflakes[i].z+snowflakes.szp
					px = (px-camx+snow_flakedist)%(snow_flakedist*2)-snow_flakedist+camx
					pz = (pz-camz+snow_flakedist)%(snow_flakedist*2)-snow_flakedist+camz
					client.model_render_bone_global(mdl_snow, mdl_snow_bone, px, py, pz, 0,0,0, 1)
				end
			end
		end

		local s_map_render = client.map_render
		if fbo_world then
			function client.map_render(...)
				client.map_render = s_map_render
				s_map_render(...)
				if shader_misc then shader_misc.push() end
				draw_snow()
				if shader_misc then shader_misc.pop() end
			end
		else
			draw_snow()
		end
		
		client.hook_render = snow_oldrender
		local ret = client.hook_render(...)
		snow_oldrender = client.hook_render
		client.hook_render = snow_render
		client.map_render = s_map_render
	end
	
	local snow_oldtick = client.hook_tick
	function snow_tick(sec_current, sec_delta)
		local xlen,ylen,zlen
		xlen,ylen,zlen = common.map_get_dims()

		--sec_delta = sec_delta * 0.05

		-- update snow wind
		local sdx,sdz
		local st = (1-math.cos(snowflakes.st*math.pi))/2
		sdx = snowflakes.sx0*(1-st)+snowflakes.sx1*st
		sdz = snowflakes.sz0*(1-st)+snowflakes.sz1*st
		snowflakes.sxp = snowflakes.sxp + sdx*sec_delta
		snowflakes.szp = snowflakes.szp + sdz*sec_delta
		snowflakes.st = snowflakes.st + sec_delta/snow_changetime
		while snowflakes.st >= 1 do
			snowflakes.sx0, snowflakes.sz0 = snowflakes.sx1, snowflakes.sz1
			snowflakes.sx1 = (math.random()*2-1)*15
			snowflakes.sz1 = (math.random()*2-1)*15
			snowflakes.st = snowflakes.st - 1
		end
		
		-- update snowflakes
		local i
		for i=1,snow_flakecount do
			local sf = snowflakes[i]
			sf.y = sf.y + sec_delta*snow_fallspeed
			if sf.y >= ylen then
				sf.x = math.random()*snow_flakedist*2
				sf.y = 0
				sf.z = math.random()*snow_flakedist*2
			end
		end

		--sec_delta = sec_delta / 0.05

		client.hook_tick = snow_oldtick
		local ret = client.hook_tick(sec_current, sec_delta)
		snow_oldtick = client.hook_tick
		client.hook_tick = snow_oldtick and snow_tick
		return ret
	end
	
	client.hook_render = snow_render
	client.hook_tick = snow_tick
end

print("Snow plugin loaded.")

