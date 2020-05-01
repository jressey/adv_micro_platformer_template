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
