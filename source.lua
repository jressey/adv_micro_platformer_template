include player.lua
include camera.lua
include collision.lua
include printer.lua

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
