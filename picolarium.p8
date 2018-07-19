pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- picolarium
-- by tobiasvl

modes={
  title=0,
  main_menu=1,
  tutorial=2,
  level_select=3,
  play=4,
  flip=5,
  verify=6,
  fail_state=7,
  win_state1=8,
  win_state2=9,
  resize=10,
  edit_custom=11,
  edit_password=12,
  custom_submenu=13,
  validate_password=14,
  valid_password=15,
  invalid_password=16
}

function load_state()
  local ls,count,d={lvls=100,lvls_beat=0},0,0
  local byte=dget(d)
  for y=1,10 do
    add(ls,{})
    for x=1,10 do
      local n=band(byte,1)
      byte=rotl(byte,1)
      add(ls[y],n)
      ls.lvls_beat+=n
      count+=1
      if count==32 then
        d+=1
        byte=dget(d)
        count=0
      end
    end
  end
  return ls
end

function save_state()
  local byte,count,d=0,0,0
  for y=1,10 do
    for x=1,10 do
      byte=bor(byte, level_select[y][x])
      byte=rotl(byte,1)
      count+=1
      if count==32 then
        dset(d,byte)
        byte=0
        d+=1
        count=0
      end
    end
  end
end

function load_custom_state()
  local level_select,custom_levels={lvls=20},{lvls=0}
  local d,state=5,rotl(dget(4),5)
  for i=1,20 do
    local level={}
    for e=0,2 do
      local l=dget(d+e)
      if (e~=2 or l~=0) add(level,l)
      if e==2 then
        level.start_pos={y=band(rotl(l,4),0xf),x=band(rotl(l,8),0xf)}
        level.end_pos={y=band(rotl(l,12),0xf),x=band(rotl(l,16),0xf)}
      end
    end
    if (#level==3) custom_levels[i]=level custom_levels.lvls+=1
    d+=3
  end
  d=1
  for y=1,4 do
    add(level_select,{})
    for x=1,5 do
      if custom_levels[d] then
        level_select[y][x]=band(state,1)
      else
        level_select[y][x]=2
      end
      state=rotl(state,1)
      d+=1
    end
  end
  return level_select,custom_levels
end

function save_level(level,lvl)
  local encoded_level=encode_level(level)
  levels[lvl]=encoded_level
  local d=2+(lvl*3)
  for i=0,2 do
    dset(d+i,encoded_level[i+1])
  end
  local x,y=lvl%#level_select[1],ceil(lvl/#level_select[1])
  if (x==0) x=#level_select[1]
  level_select[y][x]=0
  dset(4,rotr(band(rotl(dget(4),4+lvl),0xfffe.ffff),4+lvl))
end

function center(str,y,c)
  c=c or 7
  print(str,64-(#str*2),y,c)
end

-- these two functions are used to easily center
-- text even if the camera is moved.
-- i regret using the camera to center the level
function save_and_reset_camera()
  poke4(0x4300,peek4(0x5f28))
  camera()
end

function restore_camera()
  poke4(0x5f28,peek4(0x4300))
end

function print_lvl_no()
  local x=62
  if (lvl>9) x-=2
  if (lvl>99) x-=2
  save_and_reset_camera()
  local c=7
  if (custom) c=levels[lvl] and 12 or 5
  print(lvl,x,116,c)
  x=lvl%#level_select[1]
  y=ceil(lvl/#level_select[1])
  if (x==0) x=#level_select[1]
  if level_select[y][x]==1 then
    center("(solved)",122,5)
  end
  restore_camera()
end

function find_unsolved()
  new_lvl=lvl+1
  local x=new_lvl%#level_select
  if (x==0) x=10
  for y=ceil(new_lvl/#level_select),10 do
    for x2=x,10 do
      if level_select[y][x2]==0 then
        new_lvl_xpos=(x2-1)*8
        new_lvl_ypos=(y-1)*8
        return true
      end
      new_lvl+=1
    end
    x=1
  end
  return false
end

function _init()
  cartdata("picolarium")
  palt(0,false)
  mode=modes.title
  menu_selection=1
  draw=false
  custom=false
  edit=false
  hint=false
  lvl=1
  level=nil
  center("by",88)
  center("tobiasvl",96)
  lvl_xpos,lvl_ypos=0,0
  counter=0
  new_lvl=1
  new_lvl_xpos=0
  new_lvl_ypos=0
  local emulated=stat(102)!=0 and stat(102)!="www.lexaloffle.com" and stat(102)!="www.playpico.com"
  buttons={o=emulated and "z" or "🅾️",x=emulated and "x" or "❎"}
end

function play_init(level)
  draw_level(level)
  w=flr((2+#level[1])/2)
  h=flr((2+#level)/2)
  xpos = w*8
  ypos = h*8
  stack = {}
end

-- fizzlefade algorithm by drpete:
-- https://www.lexaloffle.com/bbs/?tid=29862
-- used and licensed under cc-by-sa https://creativecommons.org/licenses/by-nc-sa/4.0/
-- modified to be tile-based instead of pixel-based
function new_fizzlefader()
 local x,y,x2,y2,f=0,0,0,0,{}
 f.step = function()
  if x < 15 then
   x += 1
  elseif y < 15 then
   x = 0
   y += 1
  else
    x=0
    y=0
    mode=modes.main_menu
    mset(3,10,32) --bug
    map()
  end

  function f(n)
   n = bxor((n*2)+shr(n,1)+7*12,n)
   n = band(n,0xf)
   return n
  end

  x2,y2=x,y
  for round=1,8 do
   next_x2=y2
   y2=bxor(x2,f(y2))
   x2=next_x2
  end
 end
 f.draw = function()
   if y2<13 then --black border at bottom
     p=mget(x2,y2)
     if p==0 or (p>=64 and p<=95) then --bug fix
       mset(x2,y2,mget(x2,y2)+32)
     end
   end
 end
 return f
end

cls(0)
f = new_fizzlefader()

function title_draw()
  f.draw()
  map()
  f.step()
end
--end fizzlefader

function turn_off_draw()
  draw=false
  pal()
  stack={}
  if (edit) level.start_pos,level.end_pos={x=0,y=0},{x=0,y=0}
  draw_level(level)
end

function verify_path()
  draw=false
  if (edit) level.end_pos={x=xpos/8,y=ypos/8}
  pal()
  bad_rows={}
  b_tiles={}
  w_tiles={}
  mset(xpos/8,ypos/8,mget(xpos/8,ypos/8)+path_tile(nil,1)) --make last border
  for y=0,(#level)+1 do
    row_color=0
    for x=0,(#level[1])+1 do
        if fget(mget(x,y),2) then--white
          if fget(mget(x,y),1) then--is a path
            mset(x,y,48)--black
            add(w_tiles,{x,y})
          end
          if row_color==0 then
            row_color=1
          elseif row_color==2 then
            del(bad_rows,y) --very dumb
            add(bad_rows,y)
          end
        elseif fget(mget(x,y),3) then--black
          if fget(mget(x,y),1) then--is a path
            mset(x,y,56)--white
            add(b_tiles,{x,y})
          end
          if row_color==0 then
            row_color=2
          elseif row_color==1 then
            del(bad_rows,y) --very dumb
            add(bad_rows,y)
          end
        else
          mset(x,y,33)--border
        end
    end
  end
  mode+=1
end

-- x delta, y delta, opposite direction
moves = {[1]={-8,0,2},
         [2]={8,0,1},
         [4]={0,-8,8},
         [8]={0,8,4}}

function move(dir)
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
  if mode==modes.title then
    if btnp(🅾️) or btnp(❎) then
      mode=modes.main_menu
    end
  elseif mode==modes.main_menu then
    if (btnp(⬆️)) menu_selection=menu_selection==1 and 3 or menu_selection-1
    if (btnp(⬇️)) menu_selection=menu_selection%3+1
    if btnp(🅾️) then
      if menu_selection==1 then
        if (custom or not level_select) custom,edit,level_select,levels,lvl,lvl_xpos,lvl_ypos=false,false,load_state(),stock_levels,1,0,0
        mode=modes.level_select
      elseif menu_selection==2 then
        if (not custom) custom,lvl,lvl_xpos,lvl_ypos,level_select,levels=true,1,0,0,load_custom_state()
        menu_selection=1
        mode=modes.custom_submenu
      elseif menu_selection==3 then
        mode=modes.tutorial
      end
    end
  elseif mode==modes.custom_submenu then
    if (btnp(⬆️)) menu_selection=menu_selection==1 and 2 or 1
    if (btnp(⬇️)) menu_selection=menu_selection%2+1
    if btnp(🅾️) then
      if (menu_selection==2 or levels.lvls>0) mode=modes.level_select
      edit=menu_selection==2
    elseif btnp(❎) then
      menu_selection=2
      mode=modes.main_menu
    end
  elseif mode==modes.tutorial then
    if (btnp(🅾️) or btnp(❎)) mode=modes.main_menu
  elseif mode==modes.level_select then
    hint=false
    menuitem(1)
    menuitem(2)
    if (custom) menuitem(1,"main menu",function() cls() palt(0,false) mode=modes.custom_submenu end)
    if btnp(⬅️) then
      if lvl%#level_select[1]~=1 then
        lvl-=1
        lvl_xpos-=8
      elseif lvl~=1 then
        lvl-=1
        lvl_xpos+=(#level_select[1]-1)*8
        lvl_ypos-=8
      end
    end
    if btnp(➡️) then
      if lvl%#level_select[1]~=0 then
        lvl+=1
        lvl_xpos+=8
      elseif lvl~=level_select.lvls then
        lvl+=1
        lvl_xpos-=(#level_select[1]-1)*8
        lvl_ypos+=8
      end
    end
    if (btnp(⬆️) and lvl>#level_select[1]) lvl-=#level_select[1] lvl_ypos-=8
    if (btnp(⬇️) and lvl<=level_select.lvls-#level_select[1]) lvl+=#level_select[1] lvl_ypos+=8
    if btnp(🅾️) then
      if edit then
        if levels[lvl] then
          empty_level=decode_level(levels[lvl])
        else
          empty_level={{0,1},{0,1},start_pos={x=0,y=0},end_pos={x=0,y=0}}
        end
        level=empty_level
        play_init(level)
        mode=modes.resize
      elseif levels[lvl] then
        mode=modes.play
        level=decode_level(levels[lvl])
        play_init(level)
      end
    elseif btnp(❎) then
      if edit then
        mode,xpos,ypos,char,line,char_xpos,char_ypos,current_char=modes.edit_password,0,0,1,1,43,92,7
        numpad_x,numpad_y=39,32
        dpad_x,dpad_y=numpad_x+30,numpad_y-1
        xpos,ypos=numpad_x-2,numpad_y-1
        current_password={}
        if levels[lvl] then
          current_password=encode_password(levels[lvl])
        else
          for i=1,3 do
            add(current_password,{0,0,0,0,0,0,0,0,0,0})
          end
        end
      else
        palt(0,false) mode=custom and modes.custom_submenu or modes.main_menu
      end
    end
  elseif mode==modes.play then
    if edit then
      menuitem(2,"edit level",function() pal() mode=modes.edit_custom end)
    else
      menuitem(1,"level select",function() turn_off_draw() pal() mode=modes.level_select end)
    end
    button=btnp()
    if button==16 then
      if draw then
        verify_path()
      else
        if (edit) level.start_pos={x=xpos/8,y=ypos/8}
        draw=true
        pal(14,11)
      end
    elseif button==32 then
      if (draw) turn_off_draw() else mode=edit and modes.edit_custom or modes.level_select
    elseif button==1 or button==2 or button==4 or button==8 then
      move(button)
    end
  elseif mode==modes.fail_state then
    counter+=1
    if (btnp(🅾️)) mode=modes.play turn_off_draw()
  elseif mode==modes.resize then
    menuitem(1,"level select",function() turn_off_draw() pal() mode=modes.level_select end)
    menuitem(2)
    local x,y=#empty_level[1],#empty_level
    if (btnp(⬆️) and y>2) empty_level[y]=nil
    if (btnp(⬇️) and y<8) then
      local new_row={0}
      for i=2,x do
        add(new_row,1)
      end
      add(empty_level,new_row)
    end
    if (btnp(➡️) and x<8) foreach(empty_level,function(x) add(x,1) end)
    if (btnp(⬅️) and x>2) foreach(empty_level,function(x) x[#x]=nil end)
    if (btnp(🅾️)) mode=modes.edit_custom play_init(empty_level)
    if (btnp(❎)) mode=modes.level_select
  elseif mode==modes.edit_custom then
    menuitem(2,"resize level",function() mode=modes.resize end)
    button=btnp()
    local x,y=xpos/8,ypos/8
    if button==16 and mget(x,y)~=33 then
      local t=empty_level[y][x]
      local flip={[0]=1,[1]=0}
      empty_level[y][x]=flip[t]
      local invalid=true
      for tile in all(empty_level[y]) do
        if (tile==t) invalid=false break
      end
      if (invalid) empty_level[y][x]=t
    elseif button==32 then
      mode=modes.play
      draw_level(level)
    elseif button==1 or button==2 or button==4 or button==8 then
      move(button)
    end
  elseif mode==modes.edit_password then
    menuitem(1,"level select",function() mode=modes.level_select end)
    poke(0x5f2d,1)
    if stat(30) then
      local key=stat(31)
      if key=="\b" then
        current_password[line][char]=0
        if char>1 then
          char-=1 char_xpos-=4
        elseif line>1 then
          line-=1 char=10 char_xpos+=36 char_ypos-=6
        end
      else
        local c=tonum(key)
        if c then
          current_password[line][char]=c
          if char==10 and line<3 then
            char=1 char_xpos=43 char_ypos+=6 line+=1
          elseif char<10 then
            char+=1
            char_xpos+=4
          end
        end
      end
    end
    if btnp(⬅️) then
      if current_char=="left" then
        current_char=6
        xpos=numpad_x+14
      elseif current_char=="ok" then
        current_char=0
        xpos=numpad_x+14
      elseif not tonum(current_char) then
        current_char="left"
        xpos=dpad_x
        ypos=dpad_y+12
      elseif current_char!=1 and current_char!=4 and current_char!=7 and current_char!=0 then
        xpos-=8 current_char-=1
      end
    elseif btnp(➡️) then
      if current_char==9 then
        current_char="up"
        xpos=dpad_x+8
      elseif current_char==6 then
        current_char="left"
        xpos=dpad_x
      elseif current_char==3 then
        current_char="down"
        xpos=dpad_x+8
      elseif current_char==0 then
        current_char="ok"
        xpos=dpad_x+8
        ypos=dpad_y+36
      elseif not tonum(current_char) then
        current_char="right"
        xpos=dpad_x+16
        ypos=dpad_y+12
      elseif tonum(current_char) and current_char>0 then
        xpos+=8 current_char+=1
      end
    elseif btnp(⬆️) then
      if current_char=="ok" then
        current_char="down"
        xpos=dpad_x+8
        ypos=dpad_y+24
      elseif not tonum(current_char) then
        current_char="up"
        xpos=dpad_x+8
        ypos=dpad_y
      elseif current_char<7 then
        ypos-=12 current_char+=3
      end
    elseif btnp(⬇️) and current_char!="ok" then
      if current_char=="down" then
        current_char="ok"
        xpos=dpad_x+8
        ypos=dpad_y+36
      elseif not tonum(current_char) then
        current_char="down"
        xpos=dpad_x+8
        ypos=dpad_y+24
      elseif current_char>2 then
        ypos+=12 current_char-=3
      end
    elseif btnp(🅾️) and (char<=10 and line <=3) then
      if current_char=="left" then
        if (char>1) char-=1 char_xpos-=4
      elseif current_char=="right" then
        if (char<10) char+=1 char_xpos+=4
      elseif current_char=="up" then
        if (line>1) line-=1 char_ypos-=6
      elseif current_char=="down" then
        if (line<3) line+=1 char_ypos+=6
      elseif current_char=="ok" then
        mode=modes.validate_password
      else
        current_password[line][char]=current_char
        if char==10 and line<3 then
          char=1 char_xpos=43 char_ypos+=6 line+=1
        elseif char<10 then
          char+=1
          char_xpos+=4
        end
      end
    end
  elseif mode==modes.validate_password then
    level=decode_level(decode_password(current_password),true)
    if (level and #level>0) mode=modes.valid_password else mode=modes.invalid_password
  elseif mode==modes.valid_password then
    if btnp(🅾️) then
      save_level(level,lvl)
      mode=modes.level_select
    elseif btnp(❎) then
      mode=modes.edit_password
    end
  elseif mode==modes.invalid_password then
    if (btnp()!=0) mode=modes.edit_password
  end
  if mode==modes.fail_state or mode==modes.win_state1 or mode==modes.win_state2 then
    if btnp(❎) then
      if (edit) mode=modes.edit_custom else mode=modes.level_select
    end
  end
  if mode==modes.win_state2 then
    if btnp(🅾️) then
      if edit then
        save_level(level,lvl)
        mode=modes.level_select
      else
        lvl,lvl_xpos,lvl_ypos=new_lvl,new_lvl_xpos,new_lvl_ypos
        level=decode_level(levels[lvl])
        mode=modes.play
        play_init(level)
      end
    end
  end
end

function _draw()
  if mode==modes.title then
    title_draw()
  elseif mode==modes.main_menu then
    for x=0,15 do
      for y=0,12 do
        if (y~=3 and y~=4) mset(x,y,32)
      end
    end
    map()
    spr(96,0,24,16,2)
    spr(128,9,104,14,3)
    local colors={{7,0},{7,0},{7,0}}
    colors[menu_selection]={0,7}
    rectfill(0,48,128,100,7)
    rectfill(48,60,80,70,colors[1][1])
    print("play",49,61,colors[1][2])
    rectfill(48,67,80,77,colors[2][1])
    print("custom",49,68,colors[2][2])
    rectfill(48,74,80,80,colors[3][1])
    print("tutorial",49,75,colors[3][2])
  elseif mode==modes.tutorial then
    rectfill(0,60,127,90,7)
    cursor(8,52)
    color(0)
    print("⬅️➡️⬆️⬇️: move")
    print(buttons.o..": start and finish a\n"..(buttons.o=="z" and "" or " ").."   single stroke\n")
    print("flip tiles so each horizontal\nline is one color")
    print("e.g. from ▒/▥ to █/▤")
  elseif mode==modes.custom_submenu then
    menuitem(1)
    local colors={levels.lvls==0 and {7,5} or {7,0},{7,0}}
    if (menu_selection==1 and levels.lvls==0) colors[1]={5,7} else colors[menu_selection]={0,7}
    for x=0,15 do
      for y=0,12 do
        if (y~=3 and y~=4) mset(x,y,32)
      end
    end
    map()
    spr(96,0,24,16,2)
    spr(128,9,104,14,3)
    rectfill(0,48,128,100,7)
    print("custom",49,61,12)
    rectfill(48,67,80,77,colors[1][1])
    print("play",49,68,colors[1][2])
    rectfill(48,74,80,80,colors[2][1])
    print("edit",49,75,colors[2][2])
  elseif mode==modes.level_select then
    palt()
    for x=0,15 do
      for y=0,15 do
        mset(x,y,0)
      end
    end
    draw_level(level_select)
    spr(0, lvl_xpos, lvl_ypos)
    camera()
    select=edit and "edit" or "select"
    center(select.." level",8)
    if edit then
      print("press "..buttons.o.." to edit level",16,16)
      print("press "..buttons.x.." to edit password",16,22)
    end
    print_lvl_no()
    if (level_select.lvls_beat==100) printg()
    if edit then
      print_password(encode_password(levels[lvl]))
    end
  elseif mode==modes.play then
    cls()
    map()
    if edit then
      save_and_reset_camera()
      center("solve level to save",8)
      center("press "..buttons.x.." to edit",16,5)
      center("press "..buttons.o.." to draw",108)
      center("use one stroke to eliminate",116,5)
      center("all black and white tiles",122,5)
      restore_camera()
    else
      menuitem(2,(hint and "hide" or "show").." hint",function() hint=not hint end)
      print_lvl_no()
    end
    if hint then
      spr(58,level.start_pos.x*8,level.start_pos.y*8)
      spr(58,level.end_pos.x*8,level.end_pos.y*8)
    end
    spr(0, xpos, ypos)
  elseif mode==modes.flip then
    local s=0
    cls()
    if (#b_tiles==0 and #w_tiles==0) mode=modes.verify
    for t in all(b_tiles) do
      s=mget(t[1],t[2])
      mset(t[1],t[2],s-1)
      if (s==49) mode=modes.verify
    end
    for t in all(w_tiles) do
      s=mget(t[1],t[2])
      mset(t[1],t[2],s+1)
      if (s==55) mode=modes.verify
    end
    map()
  elseif mode==modes.verify or mode==modes.fail_state then
    if #bad_rows==0 then
      local x,y=lvl%#level_select[1],ceil(lvl/#level_select[1])
      if (x==0) x=#level_select[1]
      if custom then
        level_select[y][x]=1
        dset(4,rotr(bor(rotl(dget(4),4+lvl),1),4+lvl))
      else
        if level_select[y][x]==0 then
          level_select[y][x]=1
          level_select.lvls_beat+=1
          save_state()
        end
      end
      camera()
      center("clear!",16,3)
      if edit then
        print_password(encode_password(encode_level(level)),true)
        print(buttons.o.." save as custom level "..lvl,20,108,7)
        print(buttons.x.." edit",20,116,7)
        mode=modes.win_state2
      else
        if not custom and level_select.lvls_beat<level_select.lvls and find_unsolved() then
          print(buttons.o.." next unsolved level",20,108,7)
          print(buttons.x.." back",20,116,7)
          mode=modes.win_state2
        else
          center(buttons.x.." back",108,7)
          mode=modes.win_state1
        end
      end
    else
      if counter>=16 then
        counter=0
        local s=0
        for y in all(bad_rows) do
          for x=1,(#level[1]) do
            s=mget(x,y)
            if s==1 or s==48 then
              s=12
            elseif s==17 or s==56 then
              s=28
            elseif s==28 or s==12 then
              s+=1
            elseif s==29 or s==13 then
              s-=1
            end
            mset(x,y,s)
          end
        end
        map()
      end
      save_and_reset_camera()
      center("failed",16,8)
      print(buttons.o.." try again",40,108,7)
      if (edit) back="edit" else back="back"
      print(buttons.x.." "..back,40,116,7)
      restore_camera()
      mode=modes.fail_state
    end
  elseif mode==modes.resize then
    local x,y=#level[1],#level
    draw_level(level)
    map()
    camera()
    center("resize level",8)
    center("press "..buttons.o.." to edit",16,5)
    center(x.." x "..y,108)
    --center("press "..buttons.o.." to edit",122,5)
  elseif mode==modes.edit_custom then
    draw_level(level)
    palt()
    spr(0, xpos, ypos)
    save_and_reset_camera()
    center("edit level",8)
    center("press "..buttons.x.." to solve",16,5)
    center("press "..buttons.o.." to flip tile",108)
    center("a single row cannot",116,5)
    center("be a solid color",122,5)
    restore_camera()
  elseif mode==modes.edit_password then
    cls()
    if levels[lvl] then
      center("password exists",8)
      center("edit the password",16,5)
    else
      center("no password",8)
      center("enter a password",16,5)
    end
    color(7)
    spr(0,xpos,ypos)
    cursor(numpad_x,numpad_y)
    print("7 8 9\n")
    print("4 5 6\n")
    print("1 2 3\n")
    print("    0")
    cursor(dpad_x,dpad_y+1)
    print("  ⬆️\n")
    print("⬅️  ➡️\n")
    print("  ⬇️\n")
    print("  ok")
    print_password(current_password)
    rect(char_xpos,char_ypos,char_xpos+4,char_ypos+6,11)
  elseif mode==modes.valid_password then
    save_and_reset_camera()
    draw_level(level)
    restore_camera()
    center("password valid!",8,3)
    print(buttons.o.." save as custom level "..lvl,20,108,7)
    print(buttons.x.." edit",20,116,7)
  elseif mode==modes.invalid_password then
    rectfill(0,8,127,13,0)
    center("password invalid!",8,8)
  end
end

function draw_border(len,y)
  for x=0,len do
    mset(x,y,33)
  end
end

function draw_level(level)
  cls()
  for x=0,32 do
    for y=0,32 do
      mset(x,y,0)
    end
  end
  local width,height=#level[1],#level
  if (mode~=modes.level_select) draw_border(width+1, 0)
  for y=1,height do
    if (mode~=modes.level_select) mset(0,y,33)
    for x=1,width do
      if mode==modes.level_select then
        mset(x-1,y-1,level[y][x]*16+1)
      else
        mset(x,y,level[y][x]*16+1)
      end
    end
    if (mode~=modes.level_select) mset(width+1,y,33)
  end
  if (mode~=modes.level_select) draw_border(width+1, height+1) width+=2 height+=2
  x=-(128-(width*8))/2
  y=-(128-(height*8))/2
  camera(x,y)
  map()
end

function decode_level(packed_bytes,check_checksum)
  local loaded_level,quad={},packed_bytes[3]
  local w,h=band(quad,0xf),band(rotr(quad,4),0xf)
  loaded_level.end_pos={y=band(rotl(quad,4),0xf),x=band(rotl(quad,8),0xf)}
  loaded_level.start_pos={y=band(rotl(quad,12),0xf),x=band(rotl(quad,16),0xf)}
  local check,checksum=band(quad,0xff),band(rotr(quad,8),0xff)
  check+=band(rotl(quad,8),0xff)+band(rotl(quad,16),0xff)
  quad=rotl(packed_bytes[1],24)
  for y=1,8 do
    if (y==5) quad=rotl(packed_bytes[2],24)
    quad=rotr(quad,8)
    local byte=band(quad,0xff)
    check+=byte
    if y<=h then
      loaded_level[y]={}
      for x=1,w do
        loaded_level[y][x]=band(byte,1)
        byte=rotr(byte,1)
      end
    end
  end
  if (check_checksum and band(check,0xff)!=checksum) return false
  return loaded_level
end

function encode_level(level)
  local byte,quad,checksum,packed_bytes,w,h=0,0,0,{},#level[1],#level
  local level2={}
  --init blank level
  for i=1,4 do
    add(level2,{1,0,1,0,1,0,1,0})
    add(level2,{0,1,0,1,0,1,0,1})
  end
  for y=1,h do
    for x=1,w do
      level2[y][x]=level[y][x]
    end
  end
  --convert level data
  for y=1,8 do
    for x=1,8 do
      byte=bor(rotr(byte,1),level2[y][x])
    end
    byte=rotl(byte,7)
    checksum+=byte
    quad=bor(rotr(quad,8),byte)
    byte=0
    if (y%4==0) add(packed_bytes,rotl(quad,8)) quad=0
  end
  quad=bor(rotl(level.start_pos.y,4),level.start_pos.x)
  checksum+=quad

  quad=rotr(quad,12)
  quad=bor(quad,level.end_pos.y)
  quad=bor(rotl(quad,4),level.end_pos.x)
  checksum+=band(0xff,quad)

  quad=rotr(quad,12)
  quad=bor(quad,h)
  quad=bor(rotl(quad,4),w)
  checksum+=band(0xff,quad)

  add(packed_bytes,rotl(bor(rotr(quad,8),band(checksum,0xff)),8))
  return packed_bytes
end

-- interpret level bytes as 32-bit unsigned integers
-- thanks to felice and mrjorts from the bbs
function encode_password(pwd)
  local bytes={}
  for v in all(pwd) do
    local s,c={},(v>=0 or v==0x8000) and 0 or v%0x.000a<0x.0004 and 6 or -4
    for i=1,10 do
      c+=v%0x.000a/0x.0001
      add(s,c%10)
      c=flr(c/10)
      v=lshr(v,1)/5
    end
    add(bytes,s)
  end
  return bytes
end

function decode_password(v)
  local bytes={}
  for byte in all(v) do
    local s=(byte[10]*1000+byte[9]*100+byte[8]*10+byte[7])*0xf.424
    s+=(byte[6]*100+byte[5]*10+byte[4])*0x.03e8
    s+=(byte[3]*100+byte[2]*10+byte[1])*0x.0001
    add(bytes,s)
  end
  return bytes
end

function print_password(pwd,centered)
  rect(42,centered and 50 or 85,84,centered and 76 or 111,12)
  rectfill(43,centered and 51 or 86,83,centered and 75 or 110,0)
  center("password",centered and 52 or 87,12)
  local y=centered and 58 or 93
  color(7)
  for v in all(pwd) do
    local x=44
    cursor(x,y)
    for d in all(v) do
      print(d,x,y)
      x+=4
    end
    y+=6
  end
end

push=add
function pop(stack)
  local v = stack[#stack]
  stack[#stack]=nil
  return v
end

--[[
levels are stored as 32-bit unsigned little-endian integers,
ie. in the same format as the password encoding, but without
the final step of reversing the decimal numbers.

based on work by jonathan roatch
https://jroatch.xyz/2011/blog/polarium-password-encoding
used and licensed under cc-by-sa https://creativecommons.org/licenses/by-nc-sa/4.0/

the first four bytes are the level data, with each byte
representing one row in the level. 0 is white, 1 is black.
each row is read from right to left.

the final byte contains three bytes: the level's size (height
followed by the width), end hint (y coordinate followed by x)
and start hint. we don't bother with the checksum in these hard-
coded levels, which also means that the non-visible portions
of the levels are just 0 instead of the checkerboard pattern.
]]
stock_levels = {
  { --1
    0b0000101000001010.0000101000001010,
    0b.0000000000001010,
    0x55.1214
  },
  { --2
    0b0000010000000100.0000010000000100,
    0b1110.0000101000001110,
    0x75.5213
  },
  { --3
    0b0001101100011011.0001101100011011,
    0b0000000000010101.0001010100010001,
    0x75.5213
  },
  { --4
    0b0000101000010101.0000101000010101,
    0b0000000000000000.0000000000010101,
    0x55.1214
  },
  { --5
    0b0011111000101110.0011111000001110,
    0b0000000000000000.0000000000001110,
    0x57.5412
  },
  { --6
    0b0000001100000011.0000110000001100,
    0b0000000000000000.0000000000000000,
    0x44.4142
  },
  { --7
    0b0000010000010100.0001110000001100,
    0b0000000000000000.0000011000000110,
    0x66.5235
  },
  { --8
    0b0100100101011011.0101101101000011,
    0b0000000000000000.0000000001001001,
    0x57.4245
  },
  { --9
    0b0000000000111110.0001110000001000,
    0b0000000000000000.0000000000000000,
    0x37.1117
  },
  { --10
    0b0010000100101101.0001111000011110,
    0b0000000000000000.0000000000000000,
    0x46.3125
  },
  { --11
    0b0000011000001001.0000100100000110,
    0b0000000000000000.0000000000000000,
    0x44.1114
  },
  { --12
    0b0100000101010101.0101010101000001,
    0b0000000000000000.0000000000000000,
    0x47.1345
  },
  { --13
    0b0010101000101010.0001010100010101,
    0b0000000000000000.0001010100010101,
    0x66.1165
  },
  { --14
    0b0000000000010001.0000010000010001,
    0b0000000000000000.0000000000000000,
    0x35.2132
  },
  { --15
    0b0000111000001010.0000111000010001,
    0b0000000000000000.0000000000010001,
    0x55.2334
  },
  { --16
    0b0000111100010001.0000111100010000,
    0b0000000000000000.0000000000010000,
    0x55.3115
  },
  { --17
    0b0000101000010101.0000101000011011,
    0b0000000000000000.0000000000011011,
    0x55.1115
  },
  { --18
    0b0000000000011100.0011011000011100,
    0b0000000000000000.0000000000000000,
    0x37.2325
  },
  { --19
    0b0000011000000011.0000010100000010,
    0b0000000000000000.0000001000000101,
    0x63.2141
  },
  { --20
    0b0000110000001010.0000010100000011,
    0b0000000000000000.0000000000000000,
    0x44.2131
  },
  { --21
    0b1111111011111110.0111110000111000,
    0b0001110000010100.0001000000010000,
    0x88.1173
  },
  { --22
    0b0110000000001110.0100111001111100,
    0b0000000001001100.0110111001100000,
    0x77.1271
  },
  { --23
    0b0001111100011011.0001111000001100,
    0b1111111011100110.1100110000011000,
    0x88.3476
  },
  { --24
    0b0010011111110001.0101000001110000,
    0b0000110000000100.0001111000111111,
    0x88.3884
  },
  { --25
    0b0100010000001110.0010010010000001,
    0b0000000000000000.0000000010011001,
    0x58.3544
  },
  { --26
    0b1000000110111101.1011110110000001,
    0b1011101111110001.1101101101111110,
    0x88.7588
  },
  { --27
    0b1110111000100000.0010000011111110,
    0b1000001011111110.1111111011001110,
    0x88.2856
  },
  { --28
    0b0100000101001101.1010100100001111,
    0b0000000000000000.0000000001111111,
    0x58.2327
  },
  { --29
    0b0110111001111000.0110001100001111,
    0b0000000000000000.0000000000010000,
    0x58.4845
  },
  { --30
    0b0000001000000010.0000001100000011,
    0b0000101001111110.1100111010000110,
    0x88.4267
  },
  { --31
    0b0101110101010101.0101110101000001,
    0b0100000101011101.0101010101011101,
    0x87.7377
  },
  { --32
    0b0001100010100101.0001100010111101,
    0b0000000000000000.0000000010100101,
    0x58.1838
  },
  { --33
    0b0000000001011101.0010101001011101,
    0b0000000000000000.0000000000000000,
    0x37.1117
  },
  { --34
    0b0000111000000111.0000111000000111,
    0b0000000000000000.0000000000000000,
    0x44.2433
  },
  { --35
    0b0000101000010001.0000101000010001,
    0b0000000000000000.0000000000010001,
    0x55.2442
  },
  { --36
    0b0101010101011101.0100000100111110,
    0b0000000000111110.0100000101011101,
    0x77.5157
  },
  { --37
    0b0010000100100001.0001001000101101,
    0b0000000000000000.0010110100010010,
    0x66.1215
  },
  { --38
    0b0000000001011010.1000000101011010,
    0b0000000000000000.0000000000000000,
    0x38.1118
  },
  { --39
    0b0001101100010101.0000010000010101,
    0b0000000000000000.0000000000000100,
    0x55.1133
  },
  { --40
    0b0000010000001010.0000010000010001,
    0b0000000000000000.0000000000010001,
    0x55.1115
  },
  { --41
    0b0001000100000100.0000010000010001,
    0b0001001100011011.0001001100011011,
    0x85.7244
  },
  { --42
    0b1111110111011111.0111011000111100,
    0b0111111001000010.0100001011000011,
    0x88.1627
  },
  { --43
    0b1111011111000111.1110011111110111,
    0b1100001110000001.0011000011110111,
    0x88.1315
  },
  { --44
    0b1110001111110111.1101010111100011,
    0b0100000100000001.0000010101000001,
    0x88.2145
  },
  { --45
    0b0001110001110111.0101011101110111,
    0b1111110011111000.1111111001110110,
    0x88.2568
  },
  { --46
    0b0011111001100011.0110001100111110,
    0b0000000000100100.0001001000100100,
    0x77.3542
  },
  { --47
    0b1011111111011011.0101101000111100,
    0b0000000000000000.0000000001100110,
    0x58.1118
  },
  { --48
    0b0000010000001010.0000101001000001,
    0b0000000001000001.0011111000100000,
    0x77.6153
  },
  { --49
    0b0001110000001110.0000110000001110,
    0b1111101000111110.0001110000011111,
    0x88.4262
  },
  { --50
    0b1010010101000010.0100001000111100,
    0b0110011000100100.0111111010000001,
    0x88.1181
  },
  { --51
    0b1101011111000111.0011110000111100,
    0b0000000000000000.0000000011000111,
    0x58.1635
  },
  { --52
    0b0001100001000010.0100001011100111,
    0b0000000000000000.0000000000011000,
    0x58.1828
  },
  { --53
    0b0001100010000001.1010010101000010,
    0b0000000000000000.0000000000011000,
    0x58.1217
  },
  { --54
    0b0011100000010000.0100001011100111,
    0b0000000000000000.0000000000101000,
    0x58.3456
  },
  { --55
    0b1110011110111101.0111101100011000,
    0b0000000000000000.0000000010100101,
    0x58.2643
  },
  { --56
    0b1000000001000010.1110011101000010,
    0b0000000000000000.0000000000111100,
    0x58.2328
  },
  { --57
    0b0110001101111111.1010101011011101,
    0b0000000000000000.0000000011100011,
    0x58.2734
  },
  { --58
    0b1000110000001100.1000000010110011,
    0b0000000000000000.0000000000001100,
    0x58.4854
  },
  { --59
    0b0100110010000000.1001010110000111,
    0b0000000000000000.0000000001001100,
    0x58.2532
  },
  { --60
    0b0100000011100111.1011110111100111,
    0b0000000000000000.0000000000011100,
    0x58.4453
  },
  { --61
    0b1100001111000011.1100001111100111,
    0b1110011100010000.1010000110000001,
    0x88.8467
  },
  { --62
    0b0000000000100010.0000100001011101,
    0b0000000001111100.0101010001111100,
    0x87.1266
  },
  { --63
    0b0000000101100111.1100001111100111,
    0b1001000111010111.1100011111100100,
    0x88.1882
  },
  { --64
    0b0111000011110100.1111000111110111,
    0b0001100110000011.0000001101100001,
    0x88.3488
  },
  { --65
    0b0010000100110101.0010000100011110,
    0b0000000000000000.0001111000100001,
    0x66.4565
  },
  { --66
    0b0111001011011011.1100001101111110,
    0b0111111011000011.1101101101100110,
    0x88.3137
  },
  { --67
    0b1101111111101111.1110111111100111,
    0b1110011111110111.1111011111111011,
    0x88.5427
  },
  { --68
    0b1011110110111101.1000000100111100,
    0b1110011101111110.1100001111100111,
    0x88.4872
  },
  { --69
    0b0111111001000010.0111111001000010,
    0b0000000001000010.0111111001000010,
    0x77.1272
  },
  { --70
    0b1000010011000001.1011001101000111,
    0b1100000110000000.1000001010000010,
    0x88.3328
  },
  { --71
    0b0010101000010101.0000101000000101,
    0b1010000001010000.1010100001010100,
    0x88.4187
  },
  { --72
    0b0001111000110011.0001111000100001,
    0b0001111000100001.0000110000100001,
    0x86.1543
  },
  { --73
    0b1101101100100100.1101101101011010,
    0b0101101011011011.0010010011011011,
    0x88.8188
  },
  { --74
    0b0101101011000011.0011110010100101,
    0b1010010100111100.1100001101011010,
    0x88.1141
  },
  { --75
    0b0010010000111100.1000000111000011,
    0b1100001110000001.0011110000100100,
    0x88.1171
  },
  { --76
    0b1010010111011011.0010010000111100,
    0b0011110000100100.1101101110100101,
    0x88.5181
  },
  { --77
    0b0101010100111110.0001010001001001,
    0b0000000001001001.0001010000111110,
    0x77.6325
  },
  { --78
    0b0111011100011100.0100100101101011,
    0b0000000001101011.0100100100011100,
    0x77.4345
  },
  { --79
    0b0010010001011010.1010010101000010,
    0b0100001010100101.0101101000100100,
    0x88.2318
  },
  { --80
    0b1011110111011011.0110011010111101,
    0b1011110101100110.1101101110111101,
    0x88.1241
  },
  { --81
    0b0000001000100010.0001110001000001,
    0b0000000001000001.0001110000100010,
    0x77.3656
  },
  { --82
    0b0010001000100010.0010001000111110,
    0b0011111000110110.0011111000110110,
    0x87.3164
  },
  { --83
    0b0010111000101010.0010001000111110,
    0b0011111000110110.0011111000110110,
    0x87.3347
  },
  { --84
    0b0100000101100011.0001010000011100,
    0b0000000000011100.0000100001110111,
    0x77.2344
  },
  { --85
    0b0011111000111110.0011011001001001,
    0b0000000001110111.0110101101011101,
    0x77.3464
  },
  { --86
    0b0011111001011101.0110101101110111,
    0b0000000001100011.0111011101001001,
    0x77.2467
  },
  { --87
    0b0100000100100010.0001010000001000,
    0b0000000000001000.0001010000100010,
    0x77.5171
  },
  { --88
    0b0011111000001000.0001010000100010,
    0b0000000000001000.0011111000001000,
    0x77.3117
  },
  { --89
    0b0011111000000010.0011111000001000,
    0b0000000000001000.0011111000100000,
    0x77.1346
  },
  { --90
    0b0000001000011111.0100001000111100,
    0b0000000000111100.0100001000011111,
    0x77.4152
  },
  { --91
    0b0110011001011010.0110011000111100,
    0b0111111011011011.1001100100111100,
    0x88.3138
  },
  { --92
    0b0011111100010101.0001111100001110,
    0b0101010000101010.0010101000111110,
    0x87.2356
  },
  { --93
    0b0111111010111101.0010010000100100,
    0b0101101010111101.0111111000111100,
    0x88.3752
  },
  { --94
    0b1010010111100001.0011111100100001,
    0b0011111110100001.1010100110100001,
    0x88.2647
  },
  { --95
    0b0001001100110010.0010110000100111,
    0b0000000000000000.0011100100001101,
    0x66.5245
  },
  { --96
    0b0101011010101111.0101010100000111,
    0b0000000010001000.1111100010101000,
    0x78.2224
  },
  { --97
    0b0111101010000110.1111111011000001,
    0b1000000101111110.0110011001011010,
    0x88.5688
  },
  { --98
    0b1110000100111111.0011001100011110,
    0b0001111000110011.1110000110001001,
    0x88.5366
  },
  { --99
    0b0011110011011011.0001100000100100,
    0b0001100000011000.0001100011011011,
    0x88.3356
  },
  { --100
    0b1110100011101110.1000100011101110,
    0b1101110010001011.1000100000111111,
    0x88.3244
  }
}

function printg()
  print('c',34,110,1)
  print('o',38,110,2)
  print('n',42,110,3)
  print('g',46,110,4)
  print('r',50,110,5)
  print('a',54,110,6)
  print('t',58,110,7)
  print('u',62,110,8)
  print('l',66,110,9)
  print('a',70,110,10)
  print('t',74,110,11)
  print('i',78,110,12)
  print('o',82,110,13)
  print('n',86,110,14)
  print('s',90,110,15)
end
__gfx__
eeeeeeee7777777797777779999999999999999999999999977777799777777999999999977777799999999999999999eeeeeeee888888880000000000000000
e000000e7666665796666659766666579666665776666659966666577666665996666659966666599666665776666659eddddd5e822222280000000000000000
e000000e7677775796777759767777579677775776777759967777577677775996777759967777599677775776777759edeeee5e828888280000000000000000
e000000e7677775796777759767777579677775776777759967777577677775996777759967777599677775776777759edeeee5e828888280000000000000000
e000000e7677775796777759767777579677775776777759967777577677775996777759967777599677775776777759edeeee5e828888280000000000000000
e000000e7677775796777759767777579677775776777759967777577677775996777759967777599677775776777759edeeee5e828888280000000000000000
e000000e7655555796555559765555579655555776555559965555577655555996555559965555599655555776555559ed55555e822222280000000000000000
eeeeeeee7777777797777779999999999777777997777779999999999999999997777779999999999999999999999999eeeeeeee888888880000000000000000
000000005555555595555559999999999999999999999999955555599555555999999999955555599999999999999999dddddddd222222220000000000000000
000000005000000590000009500000059000000550000009900000055000000990000009900000099000000550000009d000000d200000020000000000000000
000000005055550590555509505555059055550550555509905555055055550990555509905555099055550550555509d0dddd0d202222020000000000000000
000000005055550590555509505555059055550550555509905555055055550990555509905555099055550550555509d0dddd0d202222020000000000000000
000000005055550590555509505555059055550550555509905555055055550990555509905555099055550550555509d0dddd0d202222020000000000000000
000000005055550590555509505555059055550550555509905555055055550990555509905555099055550550555509d0dddd0d202222020000000000000000
000000005000000590000009500000059000000550000009900000055000000990000009900000099000000550000009d000000d200000020000000000000000
000000005555555595555559999999999555555995555559999999999999999995555559999999999999999999999999dddddddd222222220000000000000000
77777777666666669666666999999999999999999999999996666669966666699999999996666669999999999999999900000000000000000000000000000000
77777777666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
77777777666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
77777777666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
77777777666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
77777777666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
77777777666666669666666966666666966666666666666996666666666666699666666996666669966666666666666900000000000000000000000000000000
77777777666666669666666999999999966666699666666999999999999999999666666999999999999999999999999900000000000000000000000000000000
77777777077777700077770000077000000750000005500000555500055555505555555555555555000000000000000000000000000000000000000000000000
76666657076665700076570000077000000750000005500000560500050000505000000550000005000000000000000000000000000000000000000000000000
76777757076775700076570000077000000750000005500000560500050550505055550550555505000330000000000000000000000000000000000000000000
767777570767757000765700000770000007500000055000005605000505505050555505505555050033b3000000000000000000000000000000000000000000
76777757076775700076570000077000000750000005500000560500050550505055550550555505003333000000000000000000000000000000000000000000
76777757076775700076570000077000000750000005500000560500050550505055550550555505000330000000000000000000000000000000000000000000
76555557076555700075570000077000000750000005500000500500050000505000000550000005000000000000000000000000000000000000000000000000
77777777077777700077770000077000000750000005500000555500055555505555555555555555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777000007707777777777777707777777777777707700000000000007777777777000007777777777000007707700000000007707777777777700000
07777777777700007707777777777777707777777777777707700000000000007777777777700007777777777700007707700000000007707777777777770000
07700000007770007707700000000000007700000000007707700000000000007700000007770007700000007770007707700000000007707700000770777000
07700000000777007707700000000000007700000000007707700000000000007700000000777007700000000777007707700000000007707700000770077700
07700000000077707707700000000000007700000000007707700000000000007700000000077707700000000077707707700000000007707700000770007770
07700000000007707707700000000000007700000000007707700000000000007700000000007707700000000007707707700000000007707700000770000770
07700000000007707707700000000000007700000000007707700000000000007700000000007707700000000007707707700000000007707700000770000770
07777777777777707707700000000000007700000000007707700000000000007777777777777707777777777777707707700000000007707700000770000770
07777777777777707707700000000000007700000000007707700000000000007777777777777707777777777777707707700000000007707700000770000770
07700000000000007707700000000000007700000000007707700000000000007700000000007707700000077000007707700000000007707700000770000770
07700000000000007707770000000000007770000000007707770000000000007700000000007707700000077700007707770000000007707700000770000770
07700000000000007700777000000000000777000000007700777000000000007700000000007707700000007770007700777000000007707700000770000770
07700000000000007700077700000000000077700000007700077700000000007700000000007707700000000777007700077700000007707700000770000770
07700000000000007700007777777777700007777777777700007777777777707700000000007707700000000077707700007777777777707700000770000770
07700000000000007700000777777777700000777777777700000777777777707700000000007707700000000007707700000777777777707700000770000770
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
70000000000777770070000000000000070000000000000070077777777777770000000000777770000000000777770070077777777770070000000000077777
70000000000077770070000000000000070000000000000070077777777777770000000000077770000000000077770070077777777770070000000000007777
70077777770007770070077777777777770077777777770070077777777777770077777770007770077777770007770070077777777770070077777007000777
70077777777000770070077777777777770077777777770070077777777777770077777777000770077777777000770070077777777770070077777007700077
70077777777700070070077777777777770077777777770070077777777777770077777777700070077777777700070070077777777770070077777007770007
70077777777770070070077777777777770077777777770070077777777777770077777777770070077777777770070070077777777770070077777007777007
70077777777770070070077777777777770077777777770070077777777777770077777777770070077777777770070070077777777770070077777007777007
70000000000000070070077777777777770077777777770070077777777777770000000000000070000000000000070070077777777770070077777007777007
70000000000000070070077777777777770077777777770070077777777777770000000000000070000000000000070070077777777770070077777007777007
70077777777777770070077777777777770077777777770070077777777777770077777777770070077777700777770070077777777770070077777007777007
70077777777777770070007777777777770007777777770070007777777777770077777777770070077777700077770070007777777770070077777007777007
70077777777777770077000777777777777000777777770077000777777777770077777777770070077777770007770077000777777770070077777007777007
70077777777777770077700077777777777700077777770077700077777777770077777777770070077777777000770077700077777770070077777007777007
70077777777777770077770000000000077770000000000077770000000000070077777777770070077777777700070077770000000000070077777007777007
70077777777777770077777000000000077777000000000077777000000000070077777777770070077777777770070077777000000000070077777007777007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007070000000000000000000
00700000000000700700000000000000000000000070000000000000000000700000000000000000000000000000000000000000000707000000000000000000
00700000000000700700007777777777777000000070000000000000000000700000000000000777777777777700000007777777770707000000000000000000
00700000000000077000000000000000007000000070000000000000000000700000000000000000000000000700000000000000000000000000000000000000
00700000000070000000000000000000007000000070000000007000000000700000000000000000000000000700000000000000000000000000000000000000
00700000007700000000000000000000007000000070000000770000000000700000000000000000000000007000000000000000000000000000000000000000
00700007770000000000000000000000007000000070000777000000000000777000000000000000000000007000000777777777777700000000000000000000
00777770000000000000000000000000007000000077777000000000000000700777000000000000000000070000000000000070000000000000000000000000
00700000000000000000000000000000007000000070000000000000000000700000770000000000000000070000000000000070000000000000000000000000
00700000000000000000000000000000007000000070000000000000000000700000007000000000000000700000000000000070000000000000000000000000
00700000000000000000000000000000007000000070000000000000000000700000000000000000000007000000000000000700000000000000000000000000
00700000000000000000000000000000007000000070000000000000000000700000000000000000000070000000000000000700000000000000000000000000
00700000000000000000000000000000007000000070000000000000000000700000000000000000000700000000000000007000000000000000000000000000
00070000000007000000007777777777777000000007000000000700000000700000000000000000007000000000000000070000000000000000000000000000
00007777777770000000000000000000007000000000777777777000000000700000000000000000770000000000000007700000000000000000000000000000
__label__
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
70000000000777770070000000000000070000000000000070077777777777770000000000777770000000000777770070077777777770070000000000077777
70000000000077770070000000000000070000000000000070077777777777770000000000077770000000000077770070077777777770070000000000007777
70077777770007770070077777777777770077777777770070077777777777770077777770007770077777770007770070077777777770070077777007000777
70077777777000770070077777777777770077777777770070077777777777770077777777000770077777777000770070077777777770070077777007700077
70077777777700070070077777777777770077777777770070077777777777770077777777700070077777777700070070077777777770070077777007770007
70077777777770070070077777777777770077777777770070077777777777770077777777770070077777777770070070077777777770070077777007777007
70077777777770070070077777777777770077777777770070077777777777770077777777770070077777777770070070077777777770070077777007777007
70000000000000070070077777777777770077777777770070077777777777770000000000000070000000000000070070077777777770070077777007777007
70000000000000070070077777777777770077777777770070077777777777770000000000000070000000000000070070077777777770070077777007777007
70077777777777770070077777777777770077777777770070077777777777770077777777770070077777700777770070077777777770070077777007777007
70077777777777770070007777777777770007777777770070007777777777770077777777770070077777700077770070007777777770070077777007777007
70077777777777770077000777777777777000777777770077000777777777770077777777770070077777770007770077000777777770070077777007777007
70077777777777770077700077777777777700077777770077700077777777770077777777770070077777777000770077700077777770070077777007777007
70077777777777770077770000000000077770000000000077770000000000070077777777770070077777777700070077770000000000070077777007777007
70077777777777770077777000000000077777000000000077777000000000070077777777770070077777777770070077777000000000070077777007777007
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777700000000000000000000000000000000077777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777707770700077707070000000000000000077777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777707070700070707070000000000000000077777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777707770700077707770000000000000000077777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777707000700070700070000000000000000077777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777707000777070707770000000000000000077777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777700000000000000000000000000000000077777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777007070770070007700700077777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777770777070707777077070700077777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777770777070700077077070707077777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777770777070777077077070707077777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777007700700777077007707077777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777770007070700077007000700070007077777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777077070770770707070770770707077777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777077070770770707007770770007077777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777077070770770707070770770707077777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777077700770770077070700070707000777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007070000000000
00000000000700000000000700700000000000000000000000070000000000000000000700000000000000000000000000000000000000000000707000000000
00000000000700000000000700700007777777777777000000070000000000000000000700000000000000777777777777700000007777777770707000000000
00000000000700000000000077000000000000000007000000070000000000000000000700000000000000000000000000700000000000000000000000000000
00000000000700000000070000000000000000000007000000070000000007000000000700000000000000000000000000700000000000000000000000000000
00000000000700000007700000000000000000000007000000070000000770000000000700000000000000000000000007000000000000000000000000000000
00000000000700007770000000000000000000000007000000070000777000000000000777000000000000000000000007000000777777777777700000000000
00000000000777770000000000000000000000000007000000077777000000000000000700777000000000000000000070000000000000070000000000000000
00000000000700000000000000000000000000000007000000070000000000000000000700000770000000000000000070000000000000070000000000000000
00000000000700000000000000000000000000000007000000070000000000000000000700000007000000000000000700000000000000070000000000000000
00000000000700000000000000000000000000000007000000070000000000000000000700000000000000000000007000000000000000700000000000000000
00000000000700000000000000000000000000000007000000070000000000000000000700000000000000000000070000000000000000700000000000000000
00000000000700000000000000000000000000000007000000070000000000000000000700000000000000000000700000000000000007000000000000000000
00000000000070000000007000000007777777777777000000007000000000700000000700000000000000000007000000000000000070000000000000000000
00000000000007777777770000000000000000000007000000000777777777000000000700000000000000000770000000000000007700000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0009060606060606060606060505000000050a0a0a0a0a0a0a0a0a0a09090000000102020202020202020202000000000505050505050505090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
404142434445464748494a4b4c4d4e4f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505152535455565758595a5b5c5d5e5f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

