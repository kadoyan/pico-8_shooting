pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function debug(o)
	local x1,y1,x2,y2=unpack(o.box)
	rect(x1,y1,x2,y2,8)
end

function game_init()
	g_time=0
	bullets={}
	smokes={}
	enemies={}
	em_bullets={}
	explosions={}
	hitmarks={}
	powerups={}
	em_counter=0
	-- added_em_list={}
	em_index=1
	em_msg={"",0}
	all_em_list={
	"00602,00A02,01002,01402,01A04,01B04,01C04,01D04,01E04,01F04,02004,02104,02204,02304,02404,02504,02604,02704,02804,02904,02A02,02E03,03202,03603,03A02,03C02,03E03,04202,04402,04A05,04E06,05006,05605,05A06,05C06,06000,06100,06200,06300,06400,06500,06600,06700,06800,06900,06A00,06B00,07001,07206,07406,07601,07806,07A06,07C01,07E06,08006,08201,08406,08606,08807,08A03,08C07,08E03,09007,09207,09407,09603,09807,09A03,09C08,09E02,0A005,0A202,0A405,0A600,0A700,0A800,0A900,0AA00,0AB00,0AC00,0AD00,0AE00,0AF00,0B000"
	}
	em_list={}
end

function _init()
	poke(0x5F2D,0x1)
	game_width=127
	game_center=flr(game_width/2)
	game_bottom=117
	srand(114)
	game_init()
	player = player_obj()
	player:new()
	status = game_status()
	status:new(player)
end
-- MARK: Update
function _update60()
	-- separate enemy data string
	if g_time==0 then
		if all_em_list[1]!="" then
			em_list=split(all_em_list[1],",",false)
		end
	end

	g_time+=1
	if g_time%30==0 then
		em_counter+=1
	end
	if not stat(57) then
		music(0)
	end
	player:update(bullets)
	for b in all(bullets) do
		b:update()
	end
	for s in all(smokes) do
		s:update()
	end

	-- MARK: show enemy number
	-- local key = stat(31)
	-- if key!="" and key!="z" and key!="x" then
	-- 	set_enemies(tonum(key))
	-- 	em_msg[1]=key
	-- 	em_msg[2]=30
	-- 	add(added_em_list, compress(em_counter,tonum(key)))
	-- 	local merged_tbl=merge_tbls(added_em_list,em_list)
	-- 	em_list_str=tbl2str(merged_tbl)
	-- 	printh(em_list_str,"@clip")
	-- end
	-- if em_msg[2]>0 then
	-- 	em_msg[2]-=1
	-- end

	-- MARK: generate enemies
	if #em_list>0 and #em_list>=em_index then
		local t,id=decompress(em_list[em_index])
		if t==em_counter then
			set_enemies(id)
			em_index+=1
		end
	end
	for e in all(enemies) do
		e:update()
	end
	for eb in all(em_bullets) do
		eb:update()
	end
	for ht in all(hitmarks) do
		ht:update()
	end
	for ex in all(explosions) do
		ex:update()
	end
	for pow in all(powerups) do
		pow:update()
	end
end

-- MARK: Draw
function _draw()
	cls(12)
	camera()
	if player.hit>10 then
		camera(rnd({1,-1}),rnd({1,-1}))
	end
	for s in all(smokes) do
		s:draw()
	end
	for b in all(bullets) do
		b:draw()
	end
	for e in all(enemies) do
		e:draw()
	end
	for eb in all(em_bullets) do
		eb:draw()
	end
	for ht in all(hitmarks) do
		ht:draw()
	end
	for ex in all(explosions) do
		ex:draw()
	end
	for pow in all(powerups) do
		pow:draw()
	end
	player:draw()
	status:draw()
	-- print("idx:"..em_index,1,1,7)
	-- print("time:"..time())
	-- if em_msg[2]>0 then
	-- 	color(8)
	-- 	print(em_msg[1].." added")
	-- end
end

-->8
-- MARK: Player
function player_obj()
	local di=0.7
	return {
		new = function(self)
			self.x,self.y=game_center-4,80
			self.dx,self.dy=0,0
			self.spd=2--moving speed
			self.sprt={1,2,3}--sprite nums
			self.sprtn=1--current sprite num
			self.shooting=false
			self.recharge=0-- shield recharging
			self.dead=false-- death flag
			self.press_x=false-- x button pressed
			self.btndir={-- button direction
				1,2,0,3,5,6,3,4,8,7,4,0,1,2,0
			}
			self.hit=0--damage counter
			self.hp=5--shield
			self.atk=8--body attack
			self.pow=1--beam power level
			self.powlist={1,1,1.5}--beam power on level
			self.pow_position={
				{0},{-3,3},{-3,3,0}
			}
			self.missile=200
			self.dirx={
				-1,1,0,0,-di,di,di,-di
			}
			self.diry={
				0,0,-1,1,-di,-di,di,di
			}
		end,
		update = function(self, bullet)
			p=self
			p.btndir[0]=0
			local dir=p.btndir[btn()&0b1111]
			p.sprtn=p.sprt[1]
			p.dx,p.dy=0,0
			if dir>0 then
				p.dx=p.dirx[dir]
				p.dy=p.diry[dir]
				p.x=mid(0,p.x+p.dx*p.spd,game_width-8)
				p.y=mid(0,p.y+p.dy*p.spd,game_bottom-12)
				p.sprtn=p.sprt[1+tonum(p.dx<0)+2*tonum(p.dx>0)]
			end
			if btn(❎) then
				if not p.press_x then
					-- single fire
					for n=1,#p.pow_position[flr(p.pow)] do
						local b=normal_bullet()
						b:new(bullet,p.x+p.pow_position[flr(p.pow)][n],p.y-(n==3 and 4 or 0),p.powlist[flr(p.pow)])
						p.press_x=true
					end
				else
					-- rapid fire
					if g_time%6==0 then
						for n=1,#p.pow_position[flr(p.pow)] do
							local b=normal_bullet()
							b:new(bullet,p.x+p.pow_position[flr(p.pow)][n],p.y-(n==3 and 4 or 0),p.powlist[flr(p.pow)])
						end
					end
				end
			else
				p.press_x=false
			end
			if btn(🅾️) then
				for n=0,1 do
					if p.missile>0 and g_time%15==0 then
						local m=missile()
						m:new(bullet,p.x,p.y,-.5+n)
						p.missile-=1
					end
				end
				-- local m=missile()
				-- m:new(bullet,p.x,p.y,.5)
			end
			p.box = {
				p.x+2,p.y+2,
				p.x+5,p.y+5
			}
			if p.hit<=0 then
				-- Player vs enemies
				for e in all(enemies) do
					if collision(p,e) then
						is_dead(enemies,e)
						p.hit = 30
						p.pow-=1
					end
				end
				-- Player vs enemy's bullets
				for b in all(em_bullets) do
					if collision(p,b) then
						del(em_bullets,b)
						p.hit = 30
						p.pow-=1
					end
				end
			else
				p.hit-=1
			end
			-- minimum power
			p.pow=max(1,p.pow)
		end,
		draw = function(self)
			if p.hit%6==0 then
				draw_afterburner(self)
				outline(self.sprtn,self.x,self.y,1,1,false,false,1,0)
			end
			-- debug(self)
			-- print(description,80,0,7)
		end
	}
end

-- player bullets
function normal_bullet()
	return {
		new = function(self,...)
			self.tbl,self.x,self.y,self.atk=...
			self.dy=-4
			add(self.tbl,self)
			sfx(0,3)
		end,
		update = function(self)
			self.y+=self.dy
			self.box = {
				self.x+1,self.y,
				self.x+7,self.y+6
			}
			if is_screenout(self) then
				del(self.tbl,self)
			end
		end,
		draw = function(self)
			spr(4,self.x,self.y)
		end
	}
end

function missile()
	return {
		dy=.5,
		spd=-0.1,
		new = function(self,...)
			-- if g_time%15==0 then
			self.tbl,self.x,self.y,self.dx=...
			self.atk=4
			add(self.tbl,self)
			-- end
		end,
		update = function(self)
			self.dy+=self.spd
			self.y+=self.dy
			self.x+=self.dx
			self.box = {
				self.x+2,self.y+1,
				self.x+6,self.y+6
			}
			if is_screenout(self) then
				del(self.tbl,self)
			end
			if g_time%2==0 then
				local s=smoke()
				s:new(smokes,self.x+4,self.y+4,0,0,flr(rnd(1))+1,rnd({15,25}),rnd({13,6,7}))
			end
		end,
		draw = function(self)
			spr(10,self.x,self.y)
		end
	}
end

function smoke()
	return {
		new = function(self,...)
			-- r:radius
			-- l:life(frame)
			self.tbl,self.x,self.y,self.dx,self.dy,self.r,self.l,self.c = ...
			add(self.tbl,self)
		end,
		update = function(self)
			self.l-=1
			self.r+=0.2
			self.x+=self.dx
			self.y+=self.dy
			if self.l<=0 then
				del(self.tbl,self)
			end
		end,
		draw = function(self)
			if self.l>=15 then
				fillp()
			elseif self.l>=10 then
				fillp(▒)
			elseif self.l>=0 then
				fillp(░)
			end
			circfill(self.x,self.y,self.r,self.c)
		end
	}
end

function explosion()
	return {
		new = function(self,...)
			self.tbl,self.x,self.y=...
			self.l,self.ex=20,{}--rnd({30}),{}
			add(self.tbl,self)
		end,
		update = function(self)
			self.l-=1
			if self.l<0 then
				del(self.tbl, self)
			elseif #self.ex<3 do
				add(self.ex,{
					dx=2-rnd(4),
					dy=2-rnd(4),
					r=5,
					sp=1,--rnd({1,.75}),
					c=rnd({10,9}),
					-- pt=rnd({█,▒,░})
				})
			end
		end,
		draw = function(self)
			local c,p={2,4,5,8,6},
			{░,░,▒,▒,█}
			-- printh(self.l\4+1)
			fillp(p[self.l\4+1])
			circfill(
			self.x,self.y,
			4+self.l\4,c[self.l\4+1])
			for e in all(self.ex) do
				e.r+=e.sp
				fillp()
				if e.r<14 then
					fillp()
				elseif e.r<16 then
					fillp(▒)
				elseif e.r<18 then
					fillp(░)
				else
					del(self.ex,e)
				end
				circfill(
				self.x+e.dx,
				self.y+e.dy+1,
				e.r\3,e.c-1)
				circfill(
				self.x+e.dx,
				self.y+e.dy,
				e.r\3,e.c)
			end
			fillp()
		end
	}
end

function hitmark()
	return {
		new = function(self,...)
			self.tbl,self.x,self.y=...
			self.l=5
			add(self.tbl,self)
		end,
		update = function(self)
			self.l-=1
			if self.l<=0 then
				del(self.tbl,self)
			end
		end,
		draw = function(self)
			circfill(self.x,self.y,5-self.l,9)
		end
	}
end

function powerup()
	return {
		new = function(self,...)
			self.tbl,self.x,self.y,self.dx,self.item=...
			self.dy=-2
			add(self.tbl,self)
		end,
		update = function(self)
			self.dy+=0.1
			self.dy=min(self.dy, 0.5)
			self.y+=self.dy
			self.box={
				self.x-4,self.y-4,
				self.x+11,self.y+11
			}
			-- get items
			if collision(self,player) then
				if self.item==1 then
					player.pow=min(3,player.pow+0.5)
				elseif self.item==2 then
					player.missile+=50
				end
				sfx(6,2)
				del(self.tbl,self)
			end
			if is_screenout(self,true) then
				del(self.tbl,self)
			end
		end,
		draw = function(self)
			local c,i,sp=1,self.item,11
			if i==2 then
				sp=12
			end
			if g_time%20>=15 then c=9 end
			outline(sp,self.x,self.y,1,1,false,false,c,0)
			-- debug(self)
		end
	}
end
-- enemy's bullets
function em_bullet()
	return {
		new = function(self,...)
			self.tbl,self.x,self.y,self.tx,self.ty,self.spd=...
			self.box={}
			local v=calc_velocity(self.x,self.y,self.tx,self.ty,self.spd)
			self.dx,self.dy=v[1],v[2]
			add(self.tbl,self)
		end,
		update = function(self)
			self.x+=self.dx
			self.y+=self.dy
			self.box={
				self.x+2,self.y+2,
				self.x+5,self.y+5
			}
			if is_screenout(self) then
				del(self.tbl,self)
			end
		end,
		draw = function(self)
			spr(6,self.x,self.y)
		end
	}
end

--MARK:status
function game_status()
	return {
		new = function(self,p)
			self.player=p
		end,
		draw = function(self)
			camera()
			fillp()
			rectfill(0,game_bottom,127,127,1)
			--missile
			local mp=32
			spr(10,mp,game_bottom+1)
			local m=self.player.missile
			print(m,mp+8,game_bottom+3,m>40 and 7 or 8)
			--power
			for x=0,5 do
				rectfill(2+5*x,game_bottom+2,5+5*x,game_bottom+8,0)
			end
			local c={12,12,9,9,8,8}
			for x=0,(self.player.pow-0.5)*2,1 do
				rectfill(2+5*x,game_bottom+2,4+5*x,game_bottom+7,c[x+1])
			end
		end
	}
end

-->8
function is_screenout(a,flag)
	local top,left,right,bottom=-8,-7,135,127
	if flag then
		top,left,right,bottom=-68,-68,187,187
	end
	return a.x<left or a.x>right or a.y<top or a.y>bottom
end
-- MARK:collision
function collision(a,b)
	if a!=nil and b!=nil then
		local x1_1, y1_1, x2_1, y2_1 = unpack(a.box)
		local x1_2, y1_2, x2_2, y2_2 = unpack(b.box)
		local result = not (x2_1 < x1_2 or x1_1 > x2_2 or y2_1 < y1_2 or y1_1 > y2_2)
		local atk
		if a.atk!=nil then atk=a.atk end
		if b.atk!=nil then atk=b.atk end
		if result then
			if a.hp!=nil then a.hp-=atk end
			if b.hp!=nil then b.hp-=atk end
		end
		return result
	else
		return false
	end
end
function is_dead(tbl,p)
	if p.hp<=0 then
		if p.item!=nil then
			item=powerup()
			item:new(powerups,p.x,p.y,p.dx,p.item)
		end
		for n=1,p.w do
			ex=explosion()
			ex:new(explosions,p.x+4*n,p.y+4*n)
		end
		del(tbl,p)
		sfx(1,3)
	else
		ht=hitmark()
		ht:new(hitmarks,p.x+4,p.y+6)
		sfx(3,3)
	end
end

function outline(s,x,y,w,h,hf,vf,c,edge)
	for p=0,15 do
		pal(p,c)
	end
	local d={
		{-1,0},{1,0},{0,-1},{0,1},
		{-1,-1},{1,1},{1,-1},{-1,1}
	}
	for i=1,4+4*edge do
		spr(s,x+d[i][1],y+d[i][2],w,h,hf,vf)
	end
	pal()
	spr(s,x,y,w,h,hf,vf)
end

function draw_afterburner(p)
	local x1,x2=
	max(p.dx,0)+2,
	min(p.dx,0)+5
	line(p.x+x1,p.y+8,
	p.x+x1,p.y+8+g_time%3-p.dy*2,8)
	line(p.x+x2,p.y+8,
	p.x+x2,p.y+8+g_time%3-p.dy*2,8)
end

function calc_velocity(px, py, tx, ty, speed)
	local dx = tx - px
	local dy = ty - py
	local length = sqrt(dx^2 + dy^2)
	local vx = (dx / length) * speed
	local vy = (dy / length) * speed
	return {vx, vy}
end
-->8
-- MARK: enemy mov
function em_straight(p)
	p.dy=p.spd
end
function em_turn(p)
	p.dx=0
	if p.y>70 then
		if p.dir==nil then
			if p.x>player.x then
				p.dir=-.75
			else
				p.dir=.75
			end
		end
		p.count-=0.04
		p.dx=cos(p.count/100)*p.dir
	end
	if flr(p.y)==90 and not p.fired then
		local b=em_bullet()
		b:new(em_bullets,p.x,p.y,player.x,player.y-10,1)
		p.fired = true
	end
	p.dy=p.count
end
function em_wave(p)
	p.dy=p.spd
	p.dx=cos(p.y/100)
	if p.y==30 then
		local b=em_bullet()
		b:new(em_bullets,p.x,p.y,player.x,player.y-10,1)
	end
end
function em_h_ramming(p)
	if p.ty-p.y>4 then
		p.dy=min((p.ty-p.y)*0.1,3)
		p.dir=(p.tx>p.x) and 1 or -1
	else
		if p.dy!=0 then
			local b=em_bullet()
			b:new(em_bullets,p.x,p.y,player.x,player.y-10,1)
		end
		p.dy=0
		p.dx+=0.1*p.dir
	end
end
function em_h_slidein(p)
	if p.count<=0 then
		p.ty=p.y
		p.r=0.55
	end
	if p.count<70 then
		p.dx=min((p.tx-p.x)*0.05,3)
		p.dy=min((p.ty-p.y)*0.05,3)
	end
	if p.count>=10 and p.count<=50 then
		if p.count%4==0 then
			p.r+=0.1
			local b=em_bullet()
			b:new(em_bullets,p.x,p.y,cos(p.r)+p.x,sin(p.r)+p.y,1)
		end
	end
	if p.count==70 then
		local v=calc_velocity(p.x,p.y,player.x,player.y,2)
		p.dx,p.dy=v[1],v[2]
	end
	p.count+=1
end
function em_round(p)
	if (p.x>=game_center-2 and p.x<=game_center) and p.flag==0 then
		p.flag=0.0075
		local b=em_bullet()
		b:new(em_bullets,p.x,p.y,player.x,player.y,1)
	end
	if p.flag!=0 then
		p.dx=cos(p.flag)*p.dir
		p.dy=sin(p.flag)*2
		p.flag+=0.0075
	end
end
function em_v_ramming(p)
	if abs(p.x-player.x)<2 and p.dy==0 then
		p.dx=0
		local sub=(p.y-player.y)
		p.dy=sub>0 and -2 or 2
	end
end
function em_curve_inout(p)
	if not p.fired and flr(p.x)==game_center then
		p.fired=true
		p.fx=not p.fx
		for n=-1,1 do
			local b=em_bullet()
			b:new(em_bullets,p.x,p.y,player.x+10*n,player.y,1)
		end
	end
	p.count+=0.004
	p.dy=sin(p.count)*2
end
function em_missile(p)
	if p.count<100 then
		p.dy=(p.ty-p.y)*0.04
	else
		p.ty=200
		p.dy=(1-((p.ty-p.y)/p.ty))*4
	end
	p.count+=1
	if p.count==60 then
		for x=-2,2 do
			local b=em_bullet()
			b:new(em_bullets,p.x,p.y,p.x+x*5,p.y+10,1)
		end
	end
end

-- MARK: enemy
description="0:bacura\n"..
"1:u turn\n"..
"2:wave\n"..
"3:h slidein\n"..
"4:h ramming\n"..
"5:circle\n"..
"6:v ramming\n"..
"7:robot\n"..
"8:missile pod\n"
function enemy()
	return {
		new = function(self,tbl,n,...)
			self.tbl,self.idx,self.dx,self.dy,self.fx,self.fy=tbl,0,0,0,false,false
			self.x,self.y,self.w,self.h=...
			self.w,self.h=
			true and self.w or 1, true and self.h or 1
			if n==0 then
				self.sprites,self.func,self.hp,
				self.spd=
				{16,17,18,19,20},em_straight,16,
				1
			elseif n==1 then
				self.sprites,self.func,self.hp,
				self.count=
				{21,22,23},em_turn,3,
				1.5
			elseif n==2 then
				self.sprites,self.func,self.hp,
				self.spd=
				{21,22,23},em_wave,2,
				1
			elseif n==3 then
				self.dir=((player.x>game_center) and 1 or -1)
				self.sprites,self.func,self.hp,
				self.tx,self.count=
				{24,25,23},em_h_slidein,2,
				self.x+64*self.dir,-abs(self.x-game_center)
			elseif n==4 then
				self.sprites,self.func,self.hp,
				self.tx,self.ty=
				{24,25,23},em_h_ramming,1,
				player.x,player.y
			elseif n==5 then
				self.sprites,self.func,self.hp,
				self.dx,self.flag=
				{21,22,23},em_round,5,
				self.x>0 and -2 or 2,0
				self.dir=self.dx
			elseif n==6 then
				self.sprites,self.func,self.hp,
				self.dx=
				{34,35,36,34},em_v_ramming,2,
				self.x>0 and -1 or 1,0
			elseif n==7 then
				self.sprites,self.func,self.hp,
				self.dx,self.dy,
				self.count,self.fired=
				{32},em_curve_inout,8,
				self.x>game_center and -0.75 or 0.75,0,
				0.75,false
				self.fx=self.dx>0 and true or false
			elseif n==8 then
				self.sprites,self.func,self.hp,
				self.ty,self.count=
				{8,9,8,7},em_missile,16,
				20,0
			else
				return false
			end
			add(tbl,self)
		end,
		update = function(self)
			self:func(self)
			self.x+=self.dx
			self.y+=self.dy
			self.box={
				self.x+2,self.y+2,
				self.x+self.w*8-2,self.y+self.h*8-2
			}
			if g_time%6==0 then
				self.idx=(self.idx+1)%#self.sprites+1
			end
			if is_screenout(self,true) then
				del(self.tbl,self)
			end
			-- enemies vs player's bullets
			for b in all(bullets) do
				if collision(self,b) then
					del(b.tbl,b)
					is_dead(self.tbl,self)
				end
			end
		end,
		draw = function(self)
			local c=1
			if self.item and g_time%10>=5 then c=9 end
			outline(self.sprites[self.idx],self.x,self.y,self.w,self.h,self.fx,self.fy,c,0)
		end
	}
end
-- MARK: set enemies
function set_enemies(id)
	local set_item=function(e,n,t,i)
		-- e:enemy obj
		-- n:current loop index
		-- t:target index
		-- i:item index
		local item_index=i and i or 1
		if n==t then
			e.item=item_index
		end
	end
	-- add(added_em_list, compress(em_counter,tonum(id)))
	-- local merged_tbl=merge_tbls(added_em_list,em_list)
	-- em_list_str=tbl2str(merged_tbl)
	-- printh(em_list_str,"@clip")
	-- set id name and x, y axis
	if id==0 then
		local x=flr(rnd(100))+10
		local e=enemy()
		e:new(enemies,id,x,-16)
	elseif id==1 then
		local x=rnd({22,game_width-30})
		for n=1,3 do
			local e=enemy()
			e:new(enemies,id,x,-10*n)
			set_item(e,n,3)
		end
	elseif id==2 then
		local x=rnd({22,game_center-4,game_width-40})
		for n=1,5 do
			local e=enemy()
			e:new(enemies,id,x,-10*n)
			set_item(e,n,5)
		end
	elseif id==3 then
		local x,y,dir=
		(player.x>game_center) and -8 or game_width,
		max(10,player.y-30),
		(player.x>game_center) and -1 or 1
		for n=1,5 do
			local e=enemy()
			e:new(enemies,id,x+n*10*dir,y)
			set_item(e,n,3)
		end
	elseif id==4 then
		local e=enemy()
		e:new(enemies,id,rnd({22,game_center-4,98}),-16)
	elseif id==5 then
		local x=rnd({-68,game_width})
		for n=1,6 do
			local e=enemy()
			e:new(enemies,id,x+n*10,100)
			set_item(e,n,6)
		end
	elseif id==6 then
		local e=enemy()
		e:new(enemies,id,rnd({-8,game_width}),player.y)
	elseif id==7 then
		local e=enemy()
		e:new(enemies,id,rnd({10,102}),-16,2,2)
	elseif id==8 then
		local e=enemy()
		e:new(enemies,id,rnd({40,80}),128)
		set_item(e,1,1,2)
	else
		return false
	end
end

-->8
-- enemymap
function decompress(n)
	local t,id
	t=tonum("0x"..sub(n,1,3),true)
	id=tonum("0x"..sub(n,4,5),true)
	return t,id
end

-- function compress(t,id)
-- 	local hex =
-- 	cnv2hex(t,4,6)..
-- 	cnv2hex(id,5,6)
-- 	return hex
-- end

-- function cnv2hex(n,s,e)
-- 	return sub(tostr(tonum(n),true),s,e)
-- end

-- function tbl2str(t)
-- 	local text=""
-- 	for i=1,#t do
-- 		text..="\""..t[i].."\","
-- 	end
-- 	return text
-- end

-- function merge_tbls(a,b)
-- 	local ta,tb,merge={},{},{}
-- 	for n=1,#a do
-- 		add(ta,a[n])
-- 	end
-- 	for n=1,#b do
-- 		add(tb,b[n])
-- 	end
-- 	local loop=#ta+#tb
-- 	for i=1,loop do
-- 		local ea,eb=ta[1],tb[1]
-- 		if (ea and eb) then
-- 			local at,bt=
-- 			decompress(ea),
-- 			decompress(eb)
-- 			if at<=bt then
-- 				add(merge,ea)
-- 				del(ta,ta[1])
-- 			else
-- 				add(merge,eb)
-- 				del(tb,tb[1])
-- 			end
-- 		else
-- 			local e=ea or eb
-- 			add(merge,e)
-- 			if ea then
-- 				del(ta,ta[1])
-- 			end
-- 			if eb then
-- 				del(tb,tb[1])
-- 			end
-- 		end
-- 	end
-- 	return merge
-- end
__gfx__
00000000007007000070700000070700000000000666666000000000000000000000000000766d000001100000aaa90000aaa900000000000000000000000000
00000000096006900060790000960600000000006677775d0000000000766d0000766d0000782500001a41000acccd900a888290000000000000000000000000
0070070007655650006576000076560000700700676cc66d00099000007825000078250000782500001941000c777cd008777820000000000000000000000000
000770000767c650067c760000767c5000a00a0067c7cc6d0097a80000782500007825000076d500001761000c7c7cd008777820000000000000000000000000
00077000076cc55006cc65000066cc5000900900671cc16d009aa8000676d5d06076d50d6002200d001761000c777cd008787820000000000000000000000000
00700700676555550676556007666550008008006761166d0008800006d555d060d5550d6008200d017656100c7cccd008787820000000000000000000000000
00000000676665650676556007665550000000006d6666dd000000000a06d090a006d009a0d555090018810009cccd4009888240000000000000000000000000
00000000079229600092950000692900000000000dddddd00000000000000000000000000006d0000000a0000099940000999400000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000006600dd000000000000000000000000000000000000000000000000000000000
077777700000000000000000000000000666666000076500000d6100000765006006d00d0776d5500006d0000000000000000000000000000000000000000000
05555550066666600000000000777700066666600076665000076500007655506067dd0d0767dd500067dd000000000000000000000000000000000000000000
05555550055555500666666007777770066666600076865000086500007622500676ddd00676ddd00676ddd00000000000000000000000000000000000000000
05555550055555500555555007777770066666600076865000086500007622500ccc11500ccc11500ccc11500000000000000000000000000000000000000000
0555555000555500000000000666666006666660007666500007650000765550c0cc15050dcc151000cc15000000000000000000000000000000000000000000
055555500000000000000000000000000555555000076500000d610000076500c00c50050ddc5110000c50000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000cc0055000000000000000000000000000000000000000000000000000000000
00007076600070000076550007600550060000d00000000000000000000000000000000000000000000000000000000000000000000650000009900000000000
0000771166570000067115d06701105d6701105d0000000000000000000000000000000000000000000000000000000000000000000760000007700000000000
0077d511566557700717815070178105701781050000000000000000000000000000000000000000000000000000000000000000000760000007700000000000
0766d1781165dd76071881507018810570188105000000000000000000000000000000000000000000000000000000000000000000d6dd00000aa00000000000
07ddd1881165dddd07611550760110557001100500000000000000000000000000000000000000000000000000000000000000000076d6000009900000000000
00555655665555100c7655d0c760055d6700005d00000000000000000000000000000000000000000000000000000000000000000076d6000008900000000000
000167111555011000c75d000c7005d06700005d0000000000000000000000000000000000000000000000000000000000000000006d5d000000200000000000
06516766115506500007500000700500070000500000000000000000000000000000000000000000000000000000000000000000000a90000002000000000000
065117661111d6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000d21155550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007765dd566660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08666655766650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02888550566588000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00228880555888200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00002220022888200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000022200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c777c77cc7c7ccccc77cc777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc7cc7c7c7c7cc7ccc7cc7c7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc7cc7c7cc7ccccccc7cc777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc7cc7c7c7c7cc7ccc7cccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c777c777c7c7ccccc777ccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c777c7c7c777ccccc777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c7ccc7c7c7c7cc7cc7c7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c77ccc7cc777ccccc7c7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c7ccc7c7c7cccc7cc7c7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c777c7c7c7ccccccc777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccc1cc1ccccccccccccccccccccccccccccccccccccccccccccccc11cc11ccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc171171ccccccccccccccccccccccccccccccccccccccccccccc17611551cccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc19611691ccccccccccccccccccccccccccccccccccccccccccc16711115d1ccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc17655651ccccccccccccccccccccccccccccccccccccccccccc1711781151ccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc1767c651ccccccccccccccccccccccccccccccccccccccccccc1711881151ccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc176cc551ccccccccccccccccccccccccccccccccccccccccccc1761111551ccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc1676555551cccccccccccccccccccccccccccccccccccccccccc1c761155d1ccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc1676665651ccccccccccccccccccccccccccccccccccccccccccc1c7115d1cccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc17922961ccccccccccccccccccccccccccccccccccccccccccccc171151ccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc111111ccccccccccccccccccccccccccccccccccccccccccccccc1cc1cccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccc8cc8cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11ccc01ccc0199901999018880188801111a41111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11ccc01ccc0199901999018880188801111941117711777171111111111111111111111111111111111111111111111111111111111111111111111111111111
11ccc01ccc0199901999018880188801111761111711717171111111111111111111111111111111111111111111111111111111111111111111111111111111
11ccc01ccc0199901999018880188801111761111711777177711111111111111111111111111111111111111111111111111111111111111111111111111111
11ccc01ccc0199901999018880188801117656111711717171711111111111111111111111111111111111111111111111111111111111111111111111111111
11ccc01ccc0199901999018880188801111881117771777177711111111111111111111111111111111111111111111111111111111111111111111111111111
110000100001000010000100001000011111a1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__sfx__
000100003f73038730007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
0001000037440354402a4401543005420004100440000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000100001535018650133400d32006310046301600000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200003f3403f330003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
00020000111510c1410812116101241013f1313f1513f101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
020400003462133621316212e6212c6212863125631216311e63119641136410d6410664100651006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
190200002f5512b55127551225511b551155511355113551175511d551255512a551335513f551005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
080200003e3313c3313133125331193310a331093310e331163311a331183310d3310333100331003010030100301003010030100301003010030100301003010030100301003010030100301003010030100301
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000c05300635006350063524635006350c053006350c05300635006350063524635006350c053006350c05300635006350063524635006350c053006350c05300635006350063524635006350c05300635
__music__
01 10424344
02 10424344

