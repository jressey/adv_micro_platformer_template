pico-8 cartridge // http://www.pico-8.com
version 7
__lua__
-- project name
-- by creator

--this is a combimation of:
--"advanced micro platformer" by
--@matthughson
--https://www.lexaloffle.com/bbs/?tid=28793
--and
--https://github.com/jayminer81/pico8_project_template
--plus some minimal graphics to pull it together

--if you make a game with this
--starter kit, please consider
--linking back to the bbs post
--for this cart, so that others
--can learn from it too!
--enjoy! 
--@matthughson

--please also consider linking to this repo

--make the player
function m_player(x,y)
  
  --todo: refactor with m_vec.
  local p=
  {
    x=x,
    y=y,

    dx=0,
    dy=0,

    w=8,
    h=8,

    max_dx=1,--max x speed
    max_dy=2,--max y speed

    jump_speed=-1.75,--jump veloclity
    acc=0.05,--acceleration
    dcc=0.8,--decceleration
    air_dcc=1,--air decceleration
    grav=0.15,

    --helper for more complex
    --button press tracking.
    --todo: generalize button index.
    jump_button=
    {
        update=function(self)
            --start with assumption
            --that not a new press.
            self.is_pressed=false
            if btn(5) then
                if not self.is_down then
                    self.is_pressed=true
                end
                self.is_down=true
                self.ticks_down+=1
            else
                self.is_down=false
                self.is_pressed=false
                self.ticks_down=0
            end
        end,
        --d
        is_pressed=false,--pressed this frame
        is_down=false,--currently down
        ticks_down=0,--how long down
    },

    jump_hold_time=0,--how long jump is held
    min_jump_press=5,--min time jump can be held
    max_jump_press=15,--max time jump can be held

    jump_btn_released=true,--can we jump again?
    grounded=false,--on ground

    airtime=0,--time since grounded
    
    --animation definitions.
    --use with set_anim()
    anims=
    {
        ["stand"]=
        {
            ticks=1,--how long is each frame shown.
            frames={1},--what frames are shown.
        },
        ["walk"]=
        {
            ticks=5,
            frames={2,3,4,5},
        },
        ["jump"]=
        {
            ticks=15,
            frames={1,3,5},
        },
        ["slide"]=
        {
            ticks=11,
            frames={7,8},
        },
    },

    curanim="walk",--currently playing animation
    curframe=1,--curent frame of animation.
    animtick=0,--ticks until next frame should show.
    flipx=false,--show sprite be flipped.

    --request new animation to play.
    set_anim=function(self,anim)
      if(anim==self.curanim)return--early out.
      local a=self.anims[anim]
      self.animtick=a.ticks--ticks count down.
      self.curanim=anim
      self.curframe=1
    end,

    --call once per tick.
    update=function(self)

      --track button presses
      local bl=btn(0) --left
      local br=btn(1) --right

      --move left/right
      if bl==true then
        self.dx-=self.acc
        br=false--handle double press
      elseif br==true then
        self.dx+=self.acc
      else
        if self.grounded then
          self.dx*=self.dcc
        else
          self.dx*=self.air_dcc
        end
      end

      --limit walk speed
      self.dx=mid(-self.max_dx,self.dx,self.max_dx)
      
      --move in x
      self.x+=self.dx
      
      --hit walls
      collide_side(self)

      --jump buttons
      self.jump_button:update()

      --jump is complex.
      --we allow jump if:
      --    on ground
      --    recently on ground
      --    pressed btn right before landing
      --also, jump velocity is
      --not instant. it applies over
      --multiple frames.
      if self.jump_button.is_down then
        --is player on ground recently.
        --allow for jump right after 
        --walking off ledge.
        local on_ground=(self.grounded or self.airtime<5)
        --was btn presses recently?
        --allow for pressing right before
        --hitting ground.
        local new_jump_btn=self.jump_button.ticks_down<10
        --is player continuing a jump
        --or starting a new one?
        if self.jump_hold_time>0 or (on_ground and new_jump_btn) then
          if(self.jump_hold_time==0)sfx(snd.jump)--new jump snd
          self.jump_hold_time+=1
          --keep applying jump velocity
          --until max jump time.
          if self.jump_hold_time<self.max_jump_press then
            self.dy=self.jump_speed--keep going up while held
          end
        end
      else
          self.jump_hold_time=0
      end

      --move in y
      self.dy+=self.grav
      self.dy=mid(-self.max_dy,self.dy,self.max_dy)
      self.y+=self.dy

      --floor
      if not collide_floor(self) then
        self:set_anim("jump")
        self.grounded=false
        self.airtime+=1
      end

      --roof
      collide_roof(self)

      --handle playing correct animation when
      --on the ground.
      if self.grounded then
        if br then
          if self.dx<0 then
              --pressing right but still moving left.
              self:set_anim("slide")
          else
              self:set_anim("walk")
          end
        elseif bl then
          if self.dx>0 then
            --pressing left but still moving right.
            self:set_anim("slide")
          else
            self:set_anim("walk")
          end
        else
          self:set_anim("stand")
        end
      end

      --flip
      if br then
        self.flipx=false
      elseif bl then
        self.flipx=true
      end

      --anim tick
      self.animtick-=1
      if self.animtick<=0 then
        self.curframe+=1
        local a=self.anims[self.curanim]
        self.animtick=a.ticks--reset timer
        if self.curframe>#a.frames then
            self.curframe=1--loop
        end
      end
    end,

    --draw the player
    draw=function(self)
      local a=self.anims[self.curanim]
      local frame=a.frames[self.curframe]
      spr(frame,
        self.x-(self.w/2),
        self.y-(self.h/2),
        self.w/8,self.h/8,
        self.flipx,
        false)
    end,
  }
  return p
end
--make the camera.
function m_cam(target)
  local c=
    {
      tar=target,--target to follow.
      pos=m_vec(target.x,target.y),
        
      --how far from center of screen target must
      --be before camera starts following.
      --allows for movement in center without camera
      --constantly moving.
      pull_threshold=16,

      --min and max positions of camera.
      --the edges of the level.
      pos_min=m_vec(64,64),
      pos_max=m_vec(320,240),
        
      shake_remaining=0,
      shake_force=0,

      update=function(self)

        self.shake_remaining=max(0,self.shake_remaining-1)
            
        --follow target outside of
        --pull range.
        if self:pull_max_x()<self.tar.x then
            self.pos.x+=min(self.tar.x-self:pull_max_x(),4)
        end
        if self:pull_min_x()>self.tar.x then
            self.pos.x+=min((self.tar.x-self:pull_min_x()),4)
        end
        if self:pull_max_y()<self.tar.y then
            self.pos.y+=min(self.tar.y-self:pull_max_y(),4)
        end
        if self:pull_min_y()>self.tar.y then
            self.pos.y+=min((self.tar.y-self:pull_min_y()),4)
        end

        --lock to edge (if past edge move to edge)
        if(self.pos.x<self.pos_min.x)self.pos.x=self.pos_min.x
        if(self.pos.x>self.pos_max.x)self.pos.x=self.pos_max.x
        if(self.pos.y<self.pos_min.y)self.pos.y=self.pos_min.y
        if(self.pos.y>self.pos_max.y)self.pos.y=self.pos_max.y
      end,

      cam_pos=function(self)
          --calculate camera shake.
          local shk=m_vec(0,0)
          if self.shake_remaining>0 then
              shk.x=rnd(self.shake_force)-(self.shake_force/2)
              shk.y=rnd(self.shake_force)-(self.shake_force/2)
          end
          return self.pos.x-64+shk.x,self.pos.y-64+shk.y
      end,

      pull_max_x=function(self)
          return self.pos.x+self.pull_threshold
      end,

      pull_min_x=function(self)
          return self.pos.x-self.pull_threshold
      end,

      pull_max_y=function(self)
          return self.pos.y+self.pull_threshold
      end,

      pull_min_y=function(self)
          return self.pos.y-self.pull_threshold
      end,
      
      shake=function(self,ticks,force)
          self.shake_remaining=ticks
          self.shake_force=force
      end
    }
  return c
end

--make 2d vector
function m_vec(x,y)
  local v=
  {
    x=x,
    y=y
  }
  return v
end
--check if pushing into side tile and resolve.
--requires subject.dx,subject.x,subject.y, and 
--assumes tile flag 0 == solid
--assumes sprite size of 8x8
function collide_side(subject)

  local offset=subject.w/3
  for i=-(subject.w/3),(subject.w/3),2 do
  --if subject.dx>0 then
    if fget(mget((subject.x+(offset))/8,(subject.y+i)/8),0) then
      subject.dx=0
      subject.x=(flr(((subject.x+(offset))/8))*8)-(offset)
      return true
    end
  --elseif subject.dx<0 then
    if fget(mget((subject.x-(offset))/8,(subject.y+i)/8),0) then
      subject.dx=0
      subject.x=(flr((subject.x-(offset))/8)*8)+8+(offset)
      return true
    end
  end
  --didn't hit a solid tile.
  return false
end

--check if pushing into floor tile and resolve.
--requires subject.dx,subject.x,subject.y,subject.grounded,subject.airtime and 
--assumes tile flag 0 or 1 == solid
function collide_floor(subject)
  --only check for ground when falling.
  if subject.dy<0 then
      return false
  end
  local landed=false
  --check for collision at multiple points along the bottom
  --of the sprite: left, center, and right.
  for i=-(subject.w/3),(subject.w/3),2 do
    local tile=mget((subject.x+i)/8,(subject.y+(subject.h/2))/8)
    if fget(tile,0) or (fget(tile,1) and subject.dy>=0) then
      subject.dy=0
      subject.y=(flr((subject.y+(subject.h/2))/8)*8)-(subject.h/2)
      subject.grounded=true
      subject.airtime=0
      landed=true
    end
  end
  return landed
end

--check if pushing into roof tile and resolve.
--requires subject.dy,subject.x,subject.y, and 
--assumes tile flag 0 == solid
function collide_roof(subject)
  --check for collision at multiple points along the top
  --of the sprite: left, center, and right.
  for i=-(subject.w/3),(subject.w/3),2 do
    if fget(mget((subject.x+i)/8,(subject.y-(subject.h/2))/8),0) then
      subject.dy=0
      subject.y=flr((subject.y-(subject.h/2))/8)*8+8+(subject.h/2)
      subject.jump_hold_time=0
    end
  end
end --print string with outline.
function printo(str,startx,starty,col,col_bg)

  print(str,startx+1,starty,col_bg)
  print(str,startx-1,starty,col_bg)
  print(str,startx,starty+1,col_bg)
  print(str,startx,starty-1,col_bg)
  print(str,startx+1,starty-1,col_bg)
  print(str,startx-1,starty-1,col_bg)
  print(str,startx-1,starty+1,col_bg)
  print(str,startx+1,starty+1,col_bg)
  print(str,startx,starty,col)
end

--print string centered with 
--outline.
function printc(str,x,y,col,col_bg,special_chars)

  local len=(#str*4)+(special_chars*3)
  local startx=x-(len/2)
  local starty=y-2
  printo(str,startx,starty,col,col_bg)
end 
--log
printh("\n\n-------\n-start-\n-------")

--sfx
snd=
{
  jump=0,
}

--music tracks
mus=
{
  bgm=0 
}

--game flow
--------------------------------

--reset the game to its initial
--state. use this instead of
--_init()
function reset()
    ticks=0
    p1=m_player(64,100)
    p1:set_anim("walk")
    cam=m_cam(p1)
    -- uncomment to enable music
    -- music(mus.bgm,300)
end

--p8 functions
--------------------------------

function _init()
    reset()
end

function _update60()
    ticks+=1
    p1:update()
    cam:update()
    --demo camera shake
    if(btnp(4))cam:shake(15,2)
end

function _draw()
    cls(0)
    camera(cam:cam_pos())
    map(0,0,0,0,128,128)
    p1:draw()
    --hud
    camera(0,0)
    printc("adv. micro platformer template",64,4,7,0,0)
end
__gfx__
00000000004440000044400000444000044440000044400000000000000444000444000000000000000000000000000000000000000000000000000000000000
00000000044f7000044f7000444f7000444f7000444f700000000000044444004444440000000000000000000000000000000000000000000000000000000000
00700700044ff000444ff0000f4ff000004ff0f0044ffff00000000007f440004444f70f00000000000000000000000000000000000000000000000000000000
00077000008888000ff88ff000f88f0000f88f0000088000000000000ff400000444fff000000000000000000000000000000000000000000000000000000000
0007700000f88f0000088000000880f00f0880000ff88000000000000f8fff000000f80000000000000000000000000000000000000000000000000000000000
0070070000f11f000001110007011000000111000001110000000000f8880000000f888100000000000000000000000000000000000000000000000000000000
00000000000110000001010000111000000107000001017000000000111100000000111100000000000000000000000000000000000000000000000000000000
00000000000770000070070000007000000700000007000000000000717100000000170700000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccc33333333cccccccccccccccccb3ccccc000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccc7cccccccccc33333333cccccccccccccccc33b3cccc000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccc777ccccccccc33333333cccccccccccccaccb443cccc000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccc7777ccccccccc33333333ccccccccccccc3ccc44ccccc000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc777ccccc33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccc777cccc33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc7777cccc33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccc33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888844444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888844444444404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888844444444404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888844444444404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888844444444404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888844444444404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888844444444404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888888844444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
5252525252525252525252525252525252525252525252525252525252525252525252525252525252525252525252520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5240424040404040404140404040404040404040404040404140404040404040424040404040404040404042404040520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5240404040404040404040404040404040404042404040404040404240404040404040404040404240404040404040520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5240404040535340404040404042404040404054545440404040404040404040404040404040404040404040404040520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5240404053534040404040404140404040425454404040404040404040404240545454545440404040404040404040520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5240404040404053535340404040404040404040404140545454545440404040404040404040404140545454404040520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5244444644454444444446454444444544464445444444444544444444444544444444444644454444444454544446520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343535343434343434343434343434343544343435353434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343535353434343434343434343434343434343545454545454434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343434343545443434343435443434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343535353434343434343434343435454434343434343434353535353434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434354545454435353534343434343434343434343434343434343434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343434354545454545443545443434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434354545454544343434343434343434354544343434343434343434343434353535343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343545443434343434343434343434343435353434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434354544343434343434343535443434343434343434343434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343545454434343535343434343435443434343545454544354545443434343534343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343435443435454544343434343434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434354545454545443435353434343434343435454544343434343434343434343534343434343435343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343435353535353535353434343534343434343434343434343434343434343435343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343434343434343434353534343434343434343434343535343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343434343434343435353434343435353534343435353534343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343434343434353534343434343434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343535353535353435343535343435343434343434343434343434343434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5243434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5353535353535353535353535353535353535353535353535353535353535353535353535353535353535353535353525300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a7a7a7a700a7a7a7a70000a7a7a70000a7a7a7a7a7a7a7a7a7a5a5a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a5a5a5a5a5a5a5a5a5a5a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003005026050200501805010050090500105000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001505013050100500d0500b050090500705005050030500205000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0020001008350200303d6100835020030083503d6100835008300200303d6100835020030083503d6100130000300000000000000000000000000000000000000000000000000000000000000000000000000000
0020000825150111001e1500000027150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
02 02004340
00 41424344
00 41424344
00 42424344

