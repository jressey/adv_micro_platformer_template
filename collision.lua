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
end