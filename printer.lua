--print string with outline.
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