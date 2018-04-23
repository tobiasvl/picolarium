pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
levels = {
  {
    {1,0,1,0,1},
    {1,0,1,0,1},
    {1,0,1,0,1},
    {1,0,1,0,1},
    {1,0,1,0,1}
  },
  {
    {0,0,1,0,0},
    {0,0,1,0,0},
    {0,0,1,0,0},
    {0,0,1,0,0},
    {0,1,1,1,0},
    {0,1,0,1,0},
    {0,1,1,1,0}
  }
}

function _init()
  pal()
  draw_level(levels[1])
  a=flr(2+#levels[1]/2)
  b=flr(3+#levels/2)
  print(a)
  xpos = a*8
  ypos = b*8
  stack = {}
  draw = false
end

function turn_off_draw()
  draw = false
  stack = {}
  draw_level(levels[1])
end

function verify_path()
  --todo
end

function move(dir)
  -- x delta, y delta, opposite direction
  moves = {[1]={-8,0,2},
           [2]={8,0,1},
           [4]={0,-8,8},
           [8]={0,8,4}}

  new_xpos=xpos+moves[dir][1]
  new_ypos=ypos+moves[dir][2]
  if draw and stack[#stack]==moves[dir][3] then
    pop(stack)
    xpos=new_xpos
    ypos=new_ypos
    new=flr(mget(xpos/8,ypos/8)/16)
    mset(xpos/8,ypos/8,new*16+1)
  elseif fget(mget(new_xpos/8,new_ypos/8),0) then
    if draw then
      mset(xpos/8,ypos/8,mget(xpos/8,ypos/8)+path_tile(stack[#stack],dir)) --path_tile()
      push(stack,dir)
    end
    xpos=new_xpos
    ypos=new_ypos
  end
end

function path_tile(dir1, dir2)
    if dir1==1 then --left
      if (dir2==1) return 2 --left/left
      if (dir2==4) return 5 --left/up
      if (dir2==8) return 3 --left/down
    elseif dir1==2 then --right
      if (dir2==2) return 2 --right/right
      if (dir2==4) return 6 --right/up
      if (dir2==8) return 4 --right/down
    elseif dir1==4 then --up
      if (dir2==4) return 1 --up/up
      if (dir2==1) return 4 --up/left
      if (dir2==2) return 3 --up/right
    elseif dir1==8 then --down
      if (dir2==8) return 1 --down/down
      if (dir2==1) return 6 --down/left
      if (dir2==2) return 5 --down/right
    elseif dir1==nil then --start
      if (dir2==1) return 10 --left
      if (dir2==2) return 9 --right
      if (dir2==4) return 8 --up
      if (dir2==8) return 7 --down
    end
end

function _update()
  if btnp(🅾️) then
    if (not draw) draw = true else verify_path()
  end
  if (btnp(❎)) turn_off_draw()
  if btnp(⬅️) or btnp(➡️) or btnp(⬆️) or btnp(⬇️) then
    move(btnp())
  end
end

function _draw()
  cls()
  map()
  spr(0, xpos, ypos)
  print(draw)
  print(stack[#stack])
end

function draw_border(len,y)
  for x=1,len do
    mset(x,y,33)
  end
end

function draw_level(level)
  width=#level[1]
  draw_border(width+2, 1)
  for y=1,#level do
    mset(1,y+1,33)
    for x=1,width do
      mset(x+1,y+1,level[y][x]*16+1)
    end
    mset(width+2,y+1,33)
  end
  draw_border(width+2, #level+2)
  map()
end

push=add

function pop(stack)
  local v = stack[#stack]
  stack[#stack]=nil
  return v
end
__gfx__
eeeeeeee777777779777777999999999999999999999999997777779977777799999999997777779999999999999999900000000000000000000000000000000
e000000e766666579666665976666657966666577666665996666657766666599666665996666659966666577666665900000000000000000000000000000000
e000000e767777579677775976777757967777577677775996777757767777599677775996777759967777577677775900000000000000000000000000000000
e000000e767777579677775976777757967777577677775996777757767777599677775996777759967777577677775900000000000000000000000000000000
e000000e767777579677775976777757967777577677775996777757767777599677775996777759967777577677775900000000000000000000000000000000
e000000e767777579677775976777757967777577677775996777757767777599677775996777759967777577677775900000000000000000000000000000000
e000000e765555579655555976555557965555577655555996555557765555599655555996555559965555577655555900000000000000000000000000000000
eeeeeeee777777779777777999999999977777799777777999999999999999999777777999999999999999999999999900000000000000000000000000000000
00000000555555559555555999999999999999999999999995555559955555599999999995555559999999999999999900000000000000000000000000000000
00000000500000059000000950000005900000055000000990000005500000099000000990000009900000055000000900000000000000000000000000000000
00000000505555059055550950555505905555055055550990555505505555099055550990555509905555055055550900000000000000000000000000000000
00000000505555059055550950555505905555055055550990555505505555099055550990555509905555055055550900000000000000000000000000000000
00000000505555059055550950555505905555055055550990555505505555099055550990555509905555055055550900000000000000000000000000000000
00000000505555059055550950555505905555055055550990555505505555099055550990555509905555055055550900000000000000000000000000000000
00000000500000059000000950000005900000055000000990000005500000099000000990000009900000055000000900000000000000000000000000000000
00000000555555559555555999999999955555599555555999999999999999999555555999999999999999999999999900000000000000000000000000000000
00000000666666669666666999999999999999999999999996666669966666699999999996666669999999999999999900000000000000000000000000000000
00000000666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
00000000666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
00000000666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
00000000666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
00000000666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
00000000666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
00000000666666669666666999999999966666699666666999999999999999999666666999999999999999999999999900000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888818888888888888888888888888888888888888888
88888eeeeee888888888888888888888888888888888888888888888888888888888888888888888888ff8171888228822888222822888888822888888228888
8888ee888ee88888888888888888888888888888888888888888888888888888888888888888888888ff88171181222222888222822888882282888888222888
888eee8e8ee88888e88888888888888888888888888888888888888888888888888888888888888888ff88171717182282888222888888228882888888288888
888eee8e8ee8888eee8888888888888888888888888888888888888888888888888888888888888888ff81177777122222888888222888228882888822288888
888eee8e8ee88888e88888888888888888888888888888888888888888888888888888888888888888ff17177777122228888228222888882282888222288888
888eee888ee888888888888888888888888888888888888888888888888888888888888888888888888ff1777777128828888228222888888822888222888888
888eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888888117771888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555517771555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555551115555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5eee5e5e5ee555ee5eee5eee55ee5ee5555555555666566556665666557555755555555555555555555555555555555555555555555555555555555555555555
5e555e5e5e5e5e5555e555e55e5e5e5e555555555565565655655565575555575555555555555555555555555555555555555555555555555555555555555555
5ee55e5e5e5e5e5555e555e55e5e5e5e555555555565565655655565575555575555555555555555555555555555555555555555555555555555555555555555
5e555e5e5e5e5e5555e555e55e5e5e5e555555555565565655655565575555575555555555555555555555555555555555555555555555555555555555555555
5e5555ee5e5e55ee55e55eee5ee55e5e555556665666565656665565557555755555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555665566656665656555556555666565656665655557556555666565656665655556657755cc555775575555555555555555555555555555555555555
5555555556565656565656565555565556555656565556555755565556555656565556555655575555c555575557555555555555555555555555555555555555
5555555556565665566656565555565556655656566556555755565556655656566556555666575555c555575557555555555555555555555555555555555555
5555555556565656565656665555565556555666565556555755565556555666565556555556575555c555575557555555555555555555555555555555555555
555555555666565656565666566656665666556556665666557556665666556556665666566557755ccc55775575555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555566655555bbb5b555bbb55755ccc5555575756555666565656665655556657755cc5557755575ccc5575555555555555555555555555555555555555
55555555565657775b555b555b5b5755555c55755777565556555656565556555655575555c555575575555c5557555555555555555555555555555555555555
55555555566655555bb55b555bb557555ccc57775757565556655656566556555666575555c5555755755ccc5557555555555555555555555555555555555555
55555555565657775b555b555b5b57555c5555755777565556555666565556555556575555c5555755755c555557555555555555555555555555555555555555
55555555565655555b555bbb5b5b55755ccc5555575756665666556556665666566557755ccc557757555ccc5575555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555566655555bbb5b555bbb55755ccc5555575756555666565656665655556655575ccc5575555555555555555555555555555555555555555555555555
55555555565657775b555b555b5b5755555c557557775655565556565655565556555575555c5557555555555555555555555555555555555555555555555555
55555555566555555bb55b555bb5575555cc5777575756555665565656655655566655755ccc5557555555555555555555555555555555555555555555555555
55555555565657775b555b555b5b5755555c5575577756555655566656555655555655755c555557555555555555555555555555555555555555555555555555
55555555566655555b555bbb5b5b55755ccc5555575756665666556556665666566557555ccc5575555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555bbb5bbb5bbb5bb55bbb5575566655755555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555b5b5b5b55b55b5b55b55755565655575555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555bbb5bb555b55b5b55b55755566655575555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555b555b5b55b55b5b55b55755565655575555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555b555b5b5bbb5b5b55b55575565655755555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555656566655665566555555555555566657575ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555656565656565655555557775555565655755c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555565566656565666555555555555566657775ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555656565556565556555557775555565655755c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555656565556655665555555555555565657575ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555656566655665566555555555555566657575ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555656565656565655555557775555565655755c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555666566656565666555555555555566557775ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555556565556565556555557775555565655755c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555666565556655665555555555555566657575ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5eee5ee55ee555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5e555e5e5e5e55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5ee55e5e5e5e55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5e555e5e5e5e55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5eee5e5e5eee55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5eee5e5e5ee555ee5eee5eee55ee5ee5555555555656566656655666566656665575557555555555555555555555555555555555555555555555555555555555
5e555e5e5e5e5e5555e555e55e5e5e5e555555555656565656565656556556555755555755555555555555555555555555555555555555555555555555555555
5ee55e5e5e5e5e5555e555e55e5e5e5e555555555656566656565666556556655755555755555555555555555555555555555555555555555555555555555555
5e555e5e5e5e5e5555e555e55e5e5e5e555555555656565556565656556556555755555755555555555555555555555555555555555555555555555555555555
5e5555ee5e5e55ee55e55eee5ee55e5e555556665566565556665656556556665575557555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555eee5eee555555755bbb5bbb5bb555755ccc557555555eee5ee55ee555555bbb55bb5bbb5bbb55755bbb55bb5bbb5bbb557556565666556655665555
5555555555e55e55555557555b5b55b55b5b57555c5c555755555e5e5e5e5e5e55555b555b555b5555b557555bbb5b555b5555b5575556565656565656555555
5555555555e55ee5555557555bb555b55b5b57555c5c555755555eee5e5e5e5e55555bb55b555bb555b557555b5b5b555bb555b5575555655666565656665777
5555555555e55e55555557555b5b55b55b5b57555c5c555755555e5e5e5e5e5e55555b555b5b5b5555b557555b5b5b5b5b5555b5575556565655565655565555
555555555eee5e55555555755bbb55b55b5b55755ccc557555555e5e5e5e5eee55555b555bbb5bbb55b555755b5b5bbb5bbb55b5557556565655566556655555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555eee5eee555555755bbb5bbb5bb555755cc5557555555eee5ee55ee555555bbb55bb5bbb5bbb55755bbb55bb5bbb5bbb557556565666556655665555
5555555555e55e55555557555b5b55b55b5b575555c5555755555e5e5e5e5e5e55555b555b555b5555b557555bbb5b555b5555b5575556565656565656555575
5555555555e55ee5555557555bb555b55b5b575555c5555755555eee5e5e5e5e55555bb55b555bb555b557555b5b5b555bb555b5575555655666565656665777
5555555555e55e55555557555b5b55b55b5b575555c5555755555e5e5e5e5e5e55555b555b5b5b5555b557555b5b5b5b5b5555b5575556565655565655565575
555555555eee5e55555555755bbb55b55b5b55755ccc557555555e5e5e5e5eee55555b555bbb5bbb55b555755b5b5bbb5bbb55b5557556565655566556655555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555eee5eee555555755bbb5bbb5bb555755ccc557555555eee5ee55ee555555bbb55bb5bbb5bbb55755bbb55bb5bbb5bbb557556565666556655665555
5555555555e55e55555557555b5b55b55b5b5755555c555755555e5e5e5e5e5e55555b555b555b5555b557555bbb5b555b5555b5575556565656565656555555
5555555555e55ee5555557555bb555b55b5b57555ccc555755555eee5e5e5e5e55555bb55b555bb555b557555b5b5b555bb555b5575555655666565656665555
5555555555e55e55555557555b5b55b55b5b57555c55555755555e5e5e5e5e5e55555b555b5b5b5555b557555b5b5b5b5b5555b5575556565655565655565575
555555555eee5e55555555755bbb55b55b5b55755ccc557555555e5e5e5e5eee55555b555bbb5bbb55b555755b5b5bbb5bbb55b5557556565655566556655755
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555eee5eee555555755bbb5bbb5bb555755ccc557555555eee5ee55ee555555bbb55bb5bbb5bbb55755bbb55bb5bbb5bbb557556565666556655665555
5555555555e55e55555557555b5b55b55b5b5755555c555755555e5e5e5e5e5e55555b555b555b5555b557555bbb5b555b5555b5575556565656565656555555
5555555555e55ee5555557555bb555b55b5b575555cc555755555eee5e5e5e5e55555bb55b555bb555b557555b5b5b555bb555b5575555655666565656665555
5555555555e55e55555557555b5b55b55b5b5755555c555755555e5e5e5e5e5e55555b555b5b5b5555b557555b5b5b5b5b5555b5575556565655565655565575
555555555eee5e55555555755bbb55b55b5b55755ccc557555555e5e5e5e5eee55555b555bbb5bbb55b555755b5b5bbb5bbb55b5557556565655566556655755
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5eee5ee55ee555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5e555e5e5e5e55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5ee55e5e5e5e55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5e555e5e5e5e55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5eee5e5e5eee55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5eee5e5e5ee555ee5eee5eee55ee5ee5555555555665566656665656557555755555555555555555555555555555555555555555555555555555555555555555
5e555e5e5e5e5e5555e555e55e5e5e5e555555555656565656565656575555575555555555555555555555555555555555555555555555555555555555555555
5ee55e5e5e5e5e5555e555e55e5e5e5e555555555656566556665656575555575555555555555555555555555555555555555555555555555555555555555555
5e555e5e5e5e5e5555e555e55e5e5e5e555555555656565656565666575555575555555555555555555555555555555555555555555555555555555555555555
5e5555ee5e5e55ee55e55eee5ee55e5e555556665666565656565666557555755555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555bb5b5555bb557555755555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555b555b555b55575555575555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555b555b555bbb575555575555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822282228882828882228888888888888888888888888888888888888888888888888222822282228882822282288222822288866688
82888828828282888888888282828828828882828888888888888888888888888888888888888888888888888882828288828828828288288282888288888888
82888828828282288888822282228828822282828888888888888888888888888888888888888888888888888222822282228828822288288222822288822288
82888828828282888888828882828828828282828888888888888888888888888888888888888888888888888288888282888828828288288882828888888888
82228222828282228888822282228288822282228888888888888888888888888888888888888888888888888222888282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0005060606060606060606060000000000090a0a0a0a0a0a0a0a0a0a00000000000102020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010700000f0500f0500f0500f0500f0500f0500f0500f0500f0500f0500f0500f0500f0500f0500f050178501e8502185027850330503305033050330503305033050270502105019050150500f0500f0510f050
011000000f0500f0500f0500f0500f0500f0500f0500f0500f0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0501c0500f0500f0500f0500f0500f0500f0500f0500f0500f050060500605006050
__music__
43 00424344
41 41424344
42 41424344
43 41424344
44 41424344
41 41424344
42 41424344
43 41424344
44 41424344
41 41424344
42 41424344
43 41424344
44 41424344
41 41424344
42 41424344
43 41424344
44 41424344
41 41424344
42 41424344
43 41424344
44 41424344
41 41424344
42 41424344
43 41424344
44 41424344
41 41424344
42 41424344
43 41424344
44 41424344
41 41424344
42 41424344
43 41424344
44 41424344
41 41424344
42 41424344
43 41424344
44 41424344
41 41424344
42 41424344
43 41424344
44 41424344
41 41424344
42 00000000
43 00000000
44 00000000
41 00000000
42 00000000
43 00000000
44 00000000
41 00000000
42 00000000
43 00000000
44 00000000
41 00000000
42 00000000
43 00000000
44 00000000
41 00000000
42 00000000
43 00000000
44 00000000
41 00000000
42 00000000
43 00414243
