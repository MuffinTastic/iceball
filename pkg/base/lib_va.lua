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

-- Vertex array API stuff
-- Basically, loaders and whatnot.
-- VA API available since 0.2a-1.

CAM_SHADING = {
	0xC0/255.0,
	0xA0/255.0,
	0xD0/255.0,
	0xE0/255.0,
	0xFF/255.0,
	0xD0/255.0,
}

--function parsekv6(pkt, name, ptsize, ptspacing)
function model_loaders.kv6(isfile, pkt, extra)
	extra = extra or {}
	if isfile then pkt = common.bin_load(pkt) end
	if not pkt then return nil end

	local scale = extra.scale or 1.0
	local ptspacing = scale
	if pkt:sub(1,4) ~= "Kvxl" then
		error("not a KV6 model")
	end

	local _

	-- load header
	local xsiz, ysiz, zsiz
	_, xsiz, ysiz, zsiz, pkt = common.net_unpack("IIII", pkt)
	local xpivot, ypivot, zpivot
	xpivot, ypivot, zpivot, pkt = common.net_unpack("fff", pkt)
	local blklen
	blklen, pkt = common.net_unpack("I", pkt)

	-- load blocks
	local l = {}
	local i
	for i=1,blklen do
		local r,g,b,z,vis
		b,g,r,_,z,vis,_,pkt = common.net_unpack("BBBBHBB", pkt)

		local vnx = (math.floor(vis/1 ) % 2) ~= 0
		local vpx = (math.floor(vis/2 ) % 2) ~= 0
		local vnz = (math.floor(vis/4 ) % 2) ~= 0
		local vpz = (math.floor(vis/8 ) % 2) ~= 0
		local vny = (math.floor(vis/16) % 2) ~= 0
		local vpy = (math.floor(vis/32) % 2) ~= 0

		l[i] = {
			--radius = ptsize,
			x = nil, z = nil, y = (z-zpivot)*ptspacing,
			r = r, g = g, b = b,
			vnx = vnx, vny = vny, vnz = vnz,
			vpx = vpx, vpy = vpy, vpz = vpz,
		}
	end

	-- skip x offsets
	pkt = pkt:sub(4*xsiz+1)

	-- load xy offsets
	-- TODO: check order
	local x,y,i,j
	i=1
	for x=1,xsiz do
	for y=1,ysiz do
		local ct
		ct, pkt = common.net_unpack("H", pkt)
		for j=1,ct do
			l[i].x = (x-xpivot)*ptspacing
			l[i].z = (y-ypivot)*ptspacing
			i = i + 1
		end
	end
	end

	-- create model
	--[[
	local mdl, mdl_bone
	mdl = common.model_new(1)
	mdl, mdl_bone = common.model_bone_new(mdl, #l)
	common.model_bone_set(mdl, mdl_bone, name, l)
	print("model data len:", #l)
	return mdl
	]]

	local spx = extra.shading_off and 1 or CAM_SHADING[1]
	local spy = extra.shading_off and 1 or CAM_SHADING[2]
	local spz = extra.shading_off and 1 or CAM_SHADING[3]
	local snx = extra.shading_off and 1 or CAM_SHADING[4]
	local sny = extra.shading_off and 1 or CAM_SHADING[5]
	local snz = extra.shading_off and 1 or CAM_SHADING[6]

	-- make
	return (function (settings)
		local this = {
			fmt = "kv6",
			tex = settings.tex or nil,
			filt = settings.filt or nil,
		} this.this = this

		local inscale = settings.inscale or 1.0
		local scale0 = scale*(0.5 - inscale/2)
		local scale1 = scale*(0.5 + inscale/2)

		-- apply filter
		local srcl = l
		local l = {}
		if this.filt then
			local i
			for i=1,#srcl do
				l[i] = {}
				l[i].r, l[i].g, l[i].b = this.filt(srcl[i].r, srcl[i].g, srcl[i].b)
				l[i].x = srcl[i].x
				l[i].y = srcl[i].y
				l[i].z = srcl[i].z
				l[i].vpx = srcl[i].vpx
				l[i].vpy = srcl[i].vpy
				l[i].vpz = srcl[i].vpz
				l[i].vnx = srcl[i].vnx
				l[i].vny = srcl[i].vny
				l[i].vnz = srcl[i].vnz
			end
		else
			l = srcl
		end

		local vl = {}
		for i=1,#l do
			local x0 = l[i].x+scale0
			local y0 = l[i].y+scale0
			local z0 = l[i].z+scale0
			local x1 = l[i].x+scale1
			local y1 = l[i].y+scale1
			local z1 = l[i].z+scale1
			local r  = l[i].r/255.0
			local g  = l[i].g/255.0
			local b  = l[i].b/255.0

			if l[i].vnx then
				vl[1+#vl] = {x0,y0,z0,r*snx,g*snx,b*snx,-1,0,0}
				vl[1+#vl] = {x0,y1,z0,r*snx,g*snx,b*snx,-1,0,0}
				vl[1+#vl] = {x0,y0,z1,r*snx,g*snx,b*snx,-1,0,0}
				vl[1+#vl] = {x0,y0,z1,r*snx,g*snx,b*snx,-1,0,0}
				vl[1+#vl] = {x0,y1,z0,r*snx,g*snx,b*snx,-1,0,0}
				vl[1+#vl] = {x0,y1,z1,r*snx,g*snx,b*snx,-1,0,0}
			end

			if l[i].vpx then
				vl[1+#vl] = {x1,y0,z0,r*spx,g*spx,b*spx,1,0,0}
				vl[1+#vl] = {x1,y0,z1,r*spx,g*spx,b*spx,1,0,0}
				vl[1+#vl] = {x1,y1,z0,r*spx,g*spx,b*spx,1,0,0}
				vl[1+#vl] = {x1,y1,z0,r*spx,g*spx,b*spx,1,0,0}
				vl[1+#vl] = {x1,y0,z1,r*spx,g*spx,b*spx,1,0,0}
				vl[1+#vl] = {x1,y1,z1,r*spx,g*spx,b*spx,1,0,0}
			end

			if l[i].vny then
				vl[1+#vl] = {x0,y0,z0,r*sny,g*sny,b*sny,0,-1,0}
				vl[1+#vl] = {x0,y0,z1,r*sny,g*sny,b*sny,0,-1,0}
				vl[1+#vl] = {x1,y0,z0,r*sny,g*sny,b*sny,0,-1,0}
				vl[1+#vl] = {x1,y0,z0,r*sny,g*sny,b*sny,0,-1,0}
				vl[1+#vl] = {x0,y0,z1,r*sny,g*sny,b*sny,0,-1,0}
				vl[1+#vl] = {x1,y0,z1,r*sny,g*sny,b*sny,0,-1,0}
			end

			if l[i].vpy then
				vl[1+#vl] = {x0,y1,z0,r*spy,g*spy,b*spy,0,1,0}
				vl[1+#vl] = {x1,y1,z0,r*spy,g*spy,b*spy,0,1,0}
				vl[1+#vl] = {x0,y1,z1,r*spy,g*spy,b*spy,0,1,0}
				vl[1+#vl] = {x0,y1,z1,r*spy,g*spy,b*spy,0,1,0}
				vl[1+#vl] = {x1,y1,z0,r*spy,g*spy,b*spy,0,1,0}
				vl[1+#vl] = {x1,y1,z1,r*spy,g*spy,b*spy,0,1,0}
			end

			if l[i].vnz then
				vl[1+#vl] = {x0,y0,z0,r*snz,g*snz,b*snz,0,0,-1}
				vl[1+#vl] = {x1,y0,z0,r*snz,g*snz,b*snz,0,0,-1}
				vl[1+#vl] = {x0,y1,z0,r*snz,g*snz,b*snz,0,0,-1}
				vl[1+#vl] = {x0,y1,z0,r*snz,g*snz,b*snz,0,0,-1}
				vl[1+#vl] = {x1,y0,z0,r*snz,g*snz,b*snz,0,0,-1}
				vl[1+#vl] = {x1,y1,z0,r*snz,g*snz,b*snz,0,0,-1}
			end

			if l[i].vpz then
				vl[1+#vl] = {x0,y0,z1,r*spz,g*spz,b*spz,0,0,1}
				vl[1+#vl] = {x0,y1,z1,r*spz,g*spz,b*spz,0,0,1}
				vl[1+#vl] = {x1,y0,z1,r*spz,g*spz,b*spz,0,0,1}
				vl[1+#vl] = {x1,y0,z1,r*spz,g*spz,b*spz,0,0,1}
				vl[1+#vl] = {x0,y1,z1,r*spz,g*spz,b*spz,0,0,1}
				vl[1+#vl] = {x1,y1,z1,r*spz,g*spz,b*spz,0,0,1}
			end
		end

		-- make
		--local i for i=1,#vl do vl[i][7] = 0.4 end
		--this.va = common.va_make(vl, nil, "3v,4c")
		if client.glsl_create then
			this.va = common.va_make(vl, nil, "3v,3c,3n")
		else
			this.va = common.va_make(vl, nil, "3v,3c")
		end

		-- conserve memory
		vl = {}

		function this.render_global(x, y, z, r1, r2, r3, s)
			client.va_render_global(this.va, x, y, z, r1, r2, r3, s, this.tex)
		end

		function this.render_local(x, y, z, r1, r2, r3, s)
			client.va_render_local(this.va, -x, y, z, r1, r2, r3, s, this.tex)
		end

		return this
	end)
end

function model_loaders.pmf(isfile, pkt, extra)
	extra = extra or {}
	--print(pkt)
	if isfile then pkt = common.fetch_block("pmf", pkt) end
	if not pkt then return nil end

	return (function(settings)
		local this = {
			fmt = "pmf",
			filt=settings.filt or nil,
		}

		this.pmf = pkt
		this.bone = extra.bone or 0

		if this.filt then
			local dname, data = common.model_bone_get(this.pmf, this.bone)
			local i
			for i=1,#data do
				data[i].r, data[i].g, data[i].b
				= this.filt(data[i].r, data[i].g, data[i].b)
			end
			this.pmf = common.model_new(1)
			this.pmf, this.bone = common.model_bone_new(this.pmf)
			common.model_bone_set(this.pmf, this.bone, dname, data)
		end

		function this.render_global(x, y, z, r1, r2, r3, s)
			client.model_render_bone_global(this.pmf, this.bone, x, y, z, r1, r2, r3, s)
		end

		function this.render_local(x, y, z, r1, r2, r3, s)
			client.model_render_bone_local(this.pmf, this.bone, x, y, z, r1, r2, r3, s)
		end

		return this
	end)
end

function model_loaders.lua(isfile, pkt, extra)
	extra = extra or {}
	--print(pkt)
	if isfile then pkt = loadfile(pkt) end
	if not pkt then return nil end

	--print(pkt)

	return pkt
end

--[[
function loadkv6(fname, name, ptsize, ptspacing)
	return parsekv6(common.bin_load(fname), name, ptsize, ptspacing)
end
]]
function loadkv6(fname, scale, filt)
	print("loadkv6", fname, scale, filt)
	return model_loaders.kv6(true, fname, {scale=scale})({filt=filt})
end

