pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function game_init()
	g_time=0
	bullets={}
	smokes={}
	enemies={}
	em_bullets={}
	explosions={}
	hitmarks={}
end

function _init()
	game_init()
	player = player_obj()
	player:init()
end

function _update60()
	g_time+=1
	if not stat(57) then
		music(0)
	end
	player:update(bullets)
	for b in all(bullets) do
		b:update()
		if is_screenout(b) then
			del(bullets,b)
		end
	end
	for s in all(smokes) do
		s:update()
		if s.l<=0 then
			del(smokes,s)
		end
	end
	set_enemies()
	for e in all(enemies) do
		e:update()
		for b in all(bullets) do
			if collision(b,e) then
				is_dead(enemies,e)
				del(bullets,b)
			end
		end
		if is_screenout(e,true) then
			del(enemies,e)
		end
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
end

function _draw()
	cls(12)
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
	player:draw()
	print(stat(0),2,2,8)
	print(stat(1),2,8,8)
	print(#em_bullets,2,14,7)
end

-->8
function player_obj()
	local di=0.7
	return {
		init = function(self)
			self.x,self.y=62,80
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
				p.x=mid(0,p.x+p.dx*p.spd,119)
				p.y=mid(0,p.y+p.dy*p.spd,110)
				p.sprtn=p.sprt[1+tonum(p.dx<0)+2*tonum(p.dx>0)]
			end
			if btn(❎) then
				if not p.press_x then
					-- single fire
					local b=normal_bullet()
					b:init(bullet,p.x,p.y)
					p.press_x=true
				else
					-- rapid fire
					if g_time%6==0 then
						local b=normal_bullet()
						b:init(bullet,p.x,p.y)
					end
				end
			else
				p.press_x=false
			end
			if btn(🅾️) then
				local m=missile()
				m:init(bullet,p.x,p.y,-.5)
				local m=missile()
				m:init(bullet,p.x,p.y,.5)
			end
			p.box = {
				p.x+2,p.x+6,
				p.y+2,p.y+6
			}
		end,
		draw = function(self)
			draw_afterburner(self)
			outline(self.sprtn,self.x,self.y,1,1,false,false,1,0)
		end
	}
end

-- player bullets
function normal_bullet()
	return {
		init = function(self,tbl,...)
			self.x,self.y=...
			self.dy,self.atk=-4,1
			add(tbl,self)
			sfx(0,3)
		end,
		update = function(self)
			self.y+=self.dy
			self.box = {
				self.x+1,self.y,
				self.x+7,self.y+6
			}
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
		init = function(self,tbl,...)
			if g_time%15==0 then
				self.x,self.y,self.dx=...
				self.atk=4
				add(tbl,self)
			end
		end,
		update = function(self)
			self.dy+=self.spd
			self.y+=self.dy
			self.x+=self.dx
			self.box = {
				self.x+2,self.y+1,
				self.x+6,self.y+6
			}
			if g_time%2==0 then
				local s=smoke()
				s:init(smokes,self.x+4,self.y+4,0,0,flr(rnd(1))+1,rnd({10,15,25}),rnd({13,6,7}))
			end
		end,
		draw = function(self)
			spr(10,self.x,self.y)
		end
	}
end

function smoke()
	return {
		init = function(self,tbl,...)
			-- r:radius
			-- l:life(frame)
			self.x,self.y,self.dx,self.dy,self.r,self.l,self.c = ...
			add(tbl,self)
		end,
		update = function(self)
			self.l-=1
			self.r+=0.2
			self.x+=self.dx
			self.y+=self.dy
		end,
		draw = function(self)
			fillp()
			if self.l>=10 then
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
		init = function(self,...)
			self.tbl,self.x,self.y=...
			self.l=0
			add(self.tbl,self)
		end,
		update = function(self)
			self.l+=1
			if self.l>11 then
				del(self.tbl, self)
			end
		end,
		draw = function(self)
			local c,p={7,10,9,9,4,2},
			{█,█,█,█,▒,▒}
			fillp(p[self.l\2+1])
			circfill(
			self.x,self.y-self.l*0.5,
			self.l,c[self.l\2+1])
			fillp()
			for n=1,4 do
				circfill(
				self.x+rnd(6)-3,
				self.y-self.l*0.5+rnd(6)-3,
				self.l\2,rnd({7,8,9}))
			end
		end
	}
end

function hitmark()
	return {
		init = function(self,...)
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
-- enemy's bullets
function em_bullet()
	return {
		init = function(self,...)
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

-->8
function is_screenout(a,flag)
	local top,left,right,bottom=-8,-7,135,128
	if flag then
		top,left,right,bottom=-60,-60,187,187
	end
	return a.x<left or a.x>right or a.y<top or a.y>bottom
end
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
		ex=explosion()
		ex:init(explosions,p.x+4,p.y+4)
		del(tbl,p)
		sfx(1,3)
	else
		ht=hitmark()
		ht:init(hitmarks,p.x+4,p.y+6)
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
-- enemy movement
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
		b:init(em_bullets,p.x,p.y,player.x,player.y-10,1)
		p.fired = true
	end
	p.dy=p.count
end
function em_wave(p)
	p.dy=p.spd
	p.dx=cos(p.y/100)
end
function em_move_atk(p)
	if p.ty-p.y>4 then
		p.dy=min((p.ty-p.y)*0.1,3)
		p.dir=(p.tx>p.x) and 1 or -1
	else
		p.dy=0
		p.dx+=0.1*p.dir
	end
end
function em_slidein_atk(p)
	if p.count<=0 then
		p.y=30
		p.ty=30
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
			b:init(em_bullets,p.x,p.y,cos(p.r)+p.x,sin(p.r)+p.y,1)
		end
	end
	-- if p.count==20 then
	-- 	for r=0,1,0.125 do
	-- 		local b=em_bullet()
	-- 		b:init(em_bullets,p.x,p.y,cos(r)+p.x,sin(r)+p.y,1)
	-- 	end
	-- end
	if p.count==70 then
		local v=calc_velocity(p.x,p.y,player.x,player.y,2)
		p.dx,p.dy=v[1],v[2]
	end
	p.count+=1
end

-- enemy
function enemy(tbl)
	return {
		init = function(self,n,...)
			self.idx,self.dx,self.dy=0,0,0
			self.x,self.y,self.w,self.h=...
			self.w,self.h=
			true and self.w or 1, true and self.h or 1
			if n==0 then
				self.sprites,self.func,self.hp,
				self.spd=
				{16,17,18,19,20},em_straight,10,
				1
			elseif n==1 then
				self.sprites,self.func,self.hp,
				self.count=
				{21,22,23},em_turn,3,
				1.5
			elseif n==2 then
				self.sprites,self.func,self.hp,
				self.spd=
				{21,22,23},em_wave,1,
				1
			elseif n==3 then
				self.dir=((player.x>64) and 1 or -1)
				self.sprites,self.func,self.hp,
				self.tx,self.count=
				{24,25,23},em_slidein_atk,1,
				self.x+60*self.dir,-abs(self.x-64)
			elseif n==4 then
				self.sprites,self.func,self.hp,
				self.tx,self.ty=
				{24,25,23},em_move_atk,1,
				player.x,player.y
			elseif n==4 then

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
		end,
		draw = function(self)
			outline(self.sprites[self.idx],self.x,self.y,self.w,self.h,false,false,1,0)
		end
	}
end
-- set enemies
function set_enemies()
	if g_time%60==0 then
		local pattern=rnd({0,1,2,3,4})
		if pattern==1 then
			local x=rnd({22,60,98})
			for n=1,3 do
				local e=enemy(enemies)
				e:init(pattern,x,-10*n)
			end
		elseif pattern==2 then
			local x=rnd({22,60,98})
			for n=1,5 do
				local e=enemy(enemies)
				e:init(pattern,20,-10*n)
			end
		elseif pattern==3 then
			local x=(player.x>64) and -8 or 128
			local dir=(player.x>64) and -1 or 1
			for n=1,4 do
				local e=enemy(enemies)
				e:init(pattern,x+n*10*dir,20)
			end
		else
			local e=enemy(enemies)
			e:init(pattern,rnd({22,60,98}),-8)
		end
	end
end

__gfx__
00000000007007000070700000070700000000000666666000000000000650000009900000000000000110000000000000000000000000000000000000000000
00000000096006900060790000960600000000006677775d00000000000760000007700000766d00001a41000000000000000000000000000000000000000000
0070070007655650006576000076560000700700676cc66d0009900000076000000770000078d500001941000000000000000000000000000000000000000000
000770000767c650067c760000767c5000a00a0067c7cc6d0097a80000d6dd00000aa0000076d500001761000000000000000000000000000000000000000000
00077000076cc55006cc65000066cc5000900900671cc16d009aa8000076d600000990000676d5d0001761000000000000000000000000000000000000000000
00700700676555550676556007666550008008006761166d000880000076d6000008900006d555d0017656100000000000000000000000000000000000000000
00000000676665650676556007665550000000006d6666dd00000000006d5d00000020000a06d090001881000000000000000000000000000000000000000000
00000000079229600092950000692900000000000dddddd000000000000a900000020000000000000000a0000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000006600dd000000000000000000000000000000000000000000000000000000000
077777700000000000000000000000000666666000076500000d6100000765006006d00d0776d5500006d0000000000000000000000000000000000000000000
05555550066666600000000000777700066666600076665000076500007655506067dd0d0767dd500067dd000000000000000000000000000000000000000000
05555550055555500666666007777770066666600076865000086500007622500676ddd00676ddd00676ddd00000000000000000000000000000000000000000
05555550055555500555555007777770066666600076865000086500007622500ccc11500ccc11500ccc11500000000000000000000000000000000000000000
0555555000555500000000000666666006666660007666500007650000765550c0cc15050dcc151000cc15000000000000000000000000000000000000000000
055555500000000000000000000000000555555000076500000d610000076500c00c50050ddc5110000c50000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000cc0055000000000000000000000000000000000000000000000000000000000
__sfx__
000100003f73038730007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
0001000037440354402a4401543005420004100440000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000100001535018650133400d32006310046301600000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200003f3403f330003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
00020000111510c1410812116101241013f1313f1513f101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
020400003462133621316212e6212c6212863125631216311e63119641136410d6410664100651006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
08030000113210a321083210732107321083210a3210d32112321173211f3212a321333213f321003010030100301003010030100301003010030100301003010030100301003010030100301003010030100301
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

