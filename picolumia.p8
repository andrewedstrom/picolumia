pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

local board
local player
local timer
local speed

-- piece types
local white = 8
local red = 16
local yellow = 24
local blue = 32
local empty = 40
local wall = -1

-- board constants
local board_height = 27 -- must be odd for math to work out
local board_width = 8
local bottom = 120
local piece_width = 8
local piece_height = 4
local sprite_size = 6

function _init()
    board=new_board()
    new_quad()

    timer = 0
    speed = 30
end

function _update()
    timer += 1
    if timer == speed then
        tick()
        timer = 0
    end

    if btnp(0) then
        move_left()
        timer = 0

    -- elseif btn(1) then
        -- move_right()
    end
end

function tick()
    move_down()
end

function move_down(next_y,next_x)
    local next_y=player.y-2
    local next_x=player.x

    if next_y > 0 and board[next_y][next_x] == empty then
        move_piece(player.y,player.x,next_y,player.x)

        local middle_two_block_x=next_x
        if not is_odd(next_y) then
            middle_two_block_x-=1
        end

        -- todo fix this
        local p1 = player:player1()
        move_piece(p1.y,p1.x,next_y+1,middle_two_block_x)

        local p2 = player:player2()
        move_piece(p2.y,p2.x,next_y+1,middle_two_block_x+1)

        local p3 = player:player3()
        move_piece(p3.y,p3.x,next_y+2,player.x)

        player.x = next_x
        player.y = next_y
    else
        new_quad()
    end
end

function move_left()
    local next_y=player.y-1
    local next_x=x_for_next_row(player.y, player.x)
    if next_y > 0 and board[next_y][next_x] == empty then
        move_piece(player.y,player.x,next_y,next_x)

        local one_row_up_x = x_for_next_row(player.y+1,next_x)
        move_piece(player.y+1,next_x,next_y+1,one_row_up_x)
        move_piece(player.y+1,next_x+1,next_y+1,one_row_up_x+1)

        move_piece(player.y+2,player.x,next_y+2,next_x)
        
        player.x = next_x
        player.y = next_y
    else
        new_quad()
    end
end

-- function move_right()
--     move_piece(player.y,player.x,next_y,next_x)
--     move_piece(player.y+1,player.x,next_y+1,next_x)
--     move_piece(player.y+1,player.x+1,next_y+1,next_x+1)
--     move_piece(player.y+2,player.x,next_y+2,next_x)
-- end


function move_piece(old_y,old_x,new_y,new_x)
    board[new_y][new_x] = board[old_y][old_x]
    board[old_y][old_x] = empty
end


function _draw()
    cls()
    rect(0,0,127,127,5)

    draw_board()
end

function draw_board()
    for y = 1, board_height do
        for x = 1, board_width do
            local x_loc=x*piece_width
            if y % 2 != 0 then
                x_loc += piece_width/2 
            end
            local y_loc=bottom-y*piece_height
            if board[y][x] != wall then
                sspr(board[y][x],0,sprite_size,sprite_size,x_loc,y_loc)
            end
        end
    end
end



-- create things

-- player is represented as the bottom of the falling quad
--     player3
-- player1  player2
--     player
function new_quad()
    player={
        y=board_height-2,
        x=4,
        player1=function(self)
            return {
                x=x_for_next_row(self.y,self.x),
                y=self.y+1
            }
        end,
        player2=function(self)
            return {
                x=x_for_next_row(self.y,self.x)+1,
                y=self.y+1
            }
        end,
        player3=function(self)
            return {
                x=self.x,
                y=self.y+2
            }
        end
    }
    local p3 = player:player3()
    board[p3.y][p3.x] = white
    
    local p2 = player:player2()
    board[p2.y][p2.x] = yellow

    local p1 = player:player1()
    board[p1.y][p1.x] = red

    board[player.y][player.x] = blue
    board[board_height-2][4] = blue
end

function new_board()
    grid = {}
    local y
    local x
    for y = 1, board_height do
        grid[y] = {}

        for x = 1, board_width do
            local piece = empty

            if wall_here(y, x) then
                piece = wall
            end

            grid[y][x] = piece
        end
    end
    return grid
end

function wall_here(y,x)
    -- todo do this much smarter
    if row_at_beginning_or_end(y, 1) and x != 4 then
        return true
    elseif row_at_beginning_or_end(y, 2) and (x < 4 or 5 < x) then
        return true
    elseif row_at_beginning_or_end(y, 3) and (x < 3 or 5 < x) then
        return true
    elseif row_at_beginning_or_end(y, 4) and (x < 3 or 6 < x) then
        return true
    elseif row_at_beginning_or_end(y, 5) and (x < 2 or 6 < x) then
        return true
    elseif row_at_beginning_or_end(y, 6) and (x < 2 or 7 < x) then
        return true
    elseif is_odd(y) and x == board_width then
        return true
    end

    return false
end

function row_at_beginning_or_end(real, expected)
    return real == expected or real == board_height-expected+1
end


-- utils
function is_odd(num)
    return num % 2 != 0
end

function x_for_next_row(current_y, current_x)
    -- either current x or x-1
    if is_odd(current_y) then
        return current_x
    end
    return current_x-1
end

__gfx__
00000000007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007007000070080880800aaaaaa00cc00cc001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770007000070080880800aaaaaa00cc00cc001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
