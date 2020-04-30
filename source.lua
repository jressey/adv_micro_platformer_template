
--advanced micro platformer
 --@matthughson

 --if you make a game with this
 --starter kit, please consider
 --linking back to the bbs post
 --for this cart, so that others
 --can learn from it too!
 --enjoy! 
 --@matthughson
                 
 --log
 printh("\n\n-------\n-start-\n-------")

 --config
 --------------------------------

 --sfx
 snd=
 {
     jump=0,
 }

 --music tracks
 mus=
 {

 }

 --math
 --------------------------------

 --point to box intersection.
 function intersects_point_box(px,py,x,y,w,h)
     if flr(px)>=flr(x) and flr(px)<flr(x+w) and
                 flr(py)>=flr(y) and flr(py)<flr(y+h) then
         return true
     else
         return false
     end
 end

 --box to box intersection
 function intersects_box_box(
     x1,y1,
     w1,h1,
     x2,y2,
     w2,h2)

     local xd=x1-x2
     local xs=w1*0.5+w2*0.5
     if abs(xd)>=xs then return false end

     local yd=y1-y2
     local ys=h1*0.5+h2*0.5
     if abs(yd)>=ys then return false end
    
     return true
 end

 --check if pushing into side tile and resolve.
 --requires self.dx,self.x,self.y, and 
 --assumes tile flag 0 == solid
 --assumes sprite size of 8x8
 function collide_side(self)

     local offset=self.w/3
     for i=-(self.w/3),(self.w/3),2 do
     --if self.dx>0 then
         if fget(mget((self.x+(offset))/8,(self.y+i)/8),0) then
             self.dx=0
             self.x=(flr(((self.x+(offset))/8))*8)-(offset)
             return true
         end
     --elseif self.dx<0 then
         if fget(mget((self.x-(offset))/8,(self.y+i)/8),0) then
             self.dx=0
             self.x=(flr((self.x-(offset))/8)*8)+8+(offset)
             return true
         end
 --    end
     end
     --didn't hit a solid tile.
     return false
 end

 --check if pushing into floor tile and resolve.
 --requires self.dx,self.x,self.y,self.grounded,self.airtime and 
 --assumes tile flag 0 or 1 == solid
 function collide_floor(self)
     --only check for ground when falling.
     if self.dy<0 then
         return false
     end
     local landed=false
     --check for collision at multiple points along the bottom
     --of the sprite: left, center, and right.
     for i=-(self.w/3),(self.w/3),2 do
         local tile=mget((self.x+i)/8,(self.y+(self.h/2))/8)
         if fget(tile,0) or (fget(tile,1) and self.dy>=0) then
             self.dy=0
             self.y=(flr((self.y+(self.h/2))/8)*8)-(self.h/2)
             self.grounded=true
             self.airtime=0
             landed=true
         end
     end
     return landed
 end

 --check if pushing into roof tile and resolve.
 --requires self.dy,self.x,self.y, and 
 --assumes tile flag 0 == solid
 function collide_roof(self)
     --check for collision at multiple points along the top
     --of the sprite: left, center, and right.
     for i=-(self.w/3),(self.w/3),2 do
         if fget(mget((self.x+i)/8,(self.y-(self.h/2))/8),0) then
             self.dy=0
             self.y=flr((self.y-(self.h/2))/8)*8+8+(self.h/2)
             self.jump_hold_time=0
         end
     end
 end

 --make 2d vector
 function m_vec(x,y)
     local v=
     {
         x=x,
         y=y,
        
   --get the length of the vector
         get_length=function(self)
             return sqrt(self.x^2+self.y^2)
         end,
        
   --get the normal of the vector
         get_norm=function(self)
             local l = self:get_length()
             return m_vec(self.x / l, self.y / l),l;
         end,
     }
     return v
 end

 --square root.
 function sqr(a) return a*a end

 --round to the nearest whole number.
 function round(a) return flr(a+0.5) end


 --utils
 --------------------------------

 --print string with outline.
 function printo(str,startx,
                                                              starty,col,
                                                              col_bg)
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
 function printc(
     str,x,y,
     col,col_bg,
     special_chars)

     local len=(#str*4)+(special_chars*3)
     local startx=x-(len/2)
     local starty=y-2
     printo(str,startx,starty,col,col_bg)
 end

 --objects
 --------------------------------

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
             --state
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
                 ticks=1,
                 frames={7},
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
    
             --todo: kill enemies.
            
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
         pos_max=m_vec(320,64),
        
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

             --lock to edge
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

     printc("adv. micro platformer",64,4,7,0,0)

 end
