pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

local board
local player_location

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
end

function _update()

end

function _draw()
    cls()
    draw_board()
    rect(0,0,127,127,5)
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
function new_quad()
    player_location={
        y=board_height-2,
        x=4
    }
    board[board_height][4] = white
    board[board_height-1][4] = red
    board[board_height-1][5] = yellow
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
    elseif y % 2 != 0 and x == board_width then
        return true
    end

    return false
end

function row_at_beginning_or_end(real, expected)
    return real == expected or real == board_height-expected+1
end


__gfx__
00000000007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007007000070080880800aaaaaa00cc00cc001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770007000070080880800aaaaaa00cc00cc001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
