pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

local board
local empty = 1
local board_height = 16
local board_width = 8
local piece_width = 8
local piece_height = 5
local sprite_size = 6

function _init()
    board=new_board()
end

function _update()

end

function _draw()
    cls()
    draw_board()
end

function draw_board()
    for y = 1, board_height do
        for x = 1, board_width do
            -- grid[y][x]
            local x_loc=x*piece_width
            if y % 2 != 0 then
                x_loc += piece_width/2 
            end
            local y_loc=122-y*piece_height
            -- rectfill(x_loc,y_loc,x_loc+piece_width-2,y_loc+piece_width-2,1)
            sspr(40,0,sprite_size,sprite_size,x_loc,y_loc)
        end
    end
end

function new_board()
    grid = {}
    local y
    local x
    for y = 1, board_height do
        grid[y] = {}

        for x = 1, board_width do
            grid[y][x] = empty
        end
    end
    return grid
end

__gfx__
00000000007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007007000070080880800aaaaaa00cc00cc001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770007000070080880800aaaaaa00cc00cc001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
