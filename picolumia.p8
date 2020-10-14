pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- picolumia
-- by andrew edstrom

local board
local player
local next_quad
local speed_timer
local speed
local last_direction_moved -- "right" or "left"
local game_state -- "playing", "gameover", "menu", "won"
local hard_dropping
local number_of_sounds=10
local combo_size

-- player-chosen settings
local display_shadow

-- coroutines
local drawing_combo_text
local blocks_clearing

-- values to display in hud
local cleared
local score
local level
local seconds_elapsed
local seconds_timer

-- block types
local white_block = 8
local red_block = 16
local yellow_block = 24
local blue_block = 32
local empty = 40
local wall = -1

-- board constants
local board_outline_color = 13
local board_left = 8 -- Used to center the board
local board_height = 27 -- must be odd for math to work out
local board_width = 8
local bottom = 117
local piece_width = 8
local piece_height = 4
local sprite_size = 6

-- game feel thiccness
local x_shift
local y_shift
local shimmy_coefficient=1.4
local shimmy_degredation_rate=.93
local minimum_shimmy_threshold=.8
local fade_speed=0.05
local current_fade_perc=0
local loading=false

-- set up palette
function setup_palette()
    _pal={0,129,136,140,1,5,6,7,8,135,10,131,12,13,133,134}
    for i,c in pairs(_pal) do
        pal(i-1,c,1)
    end
end

function _init()
    game_state="menu"
    turn_on_shadow()
end

function start_game()
    board=new_board()
    game_state = "playing"
    setup_palette()
    make_next_quad()
    new_player_quad()
    last_direction_moved="right"
    speed_timer = 0
    seconds_timer = 0
    seconds_elapsed = 0
    speed = 27
    cleared = 0
    combo_size = 0
    level = 0
    score = 0
    x_shift = 0
    y_shift = 0
    hard_dropping = false
end

function currently_clearing_blocks()
    return blocks_clearing and costatus(blocks_clearing) != 'dead'
end

function handle_input()
    local just_moved=false
    if btnp(0) then
        just_moved=move_left()
        x_shift=shimmy_coefficient
    elseif btnp(1) then
        just_moved=move_right()
        x_shift=-shimmy_coefficient
    elseif btn(3) then
        hard_dropping=true
        move_down()
        y_shift-=shimmy_coefficient
    end
    if just_moved then
        move_sound()
    end

    if btnp(4) then
        rotate_counter_clockwise()
        move_sound()
    elseif btnp(5) then
        rotate_clockwise()
        move_sound()
    end
end

function get_screen_position_for_block(y,x)
    local x_loc=x*piece_width + board_left
    if is_odd(y) then
        x_loc += piece_width/2
    end
    local y_loc=bottom-y*piece_height
    return y_loc, x_loc
end

-- return time elapsed in format mm:ss
function display_time()
    local minutes = flr(seconds_elapsed / 60)
    local seconds_remainder = seconds_elapsed % 60
    local display_minutes = tostr(minutes)
    if #display_minutes < 2 then
        display_minutes = "0" .. display_minutes
    end
    local display_seconds = tostr(seconds_remainder)
    if #display_seconds < 2 then
        display_seconds = "0" .. display_seconds
    end

    return display_minutes .. ":" .. display_seconds
end

function tick()
    move_down()
end

function move_sound()
    sfx(flr(rnd(number_of_sounds+1)))
end

function calculate_points_scored(blocks_cleared)
    return (level+1)*((blocks_cleared-2)^2)
end

function yield_n_times(n)
    local i
    for i=1,n do
        yield()
    end
end

function let_pieces_settle()
    --todo do this as a coroutine too
    local falling=true
    while falling do
        falling=false
        -- todo make this happen over multiple frames
        for_all_tiles(function(y,x)
            if board[y][x] != empty then
                if block_can_fall_left(y,x) then
                    move_piece(y, x, y-1, x_for_next_row(y,x))
                    falling=true
                end
            end
        end)
        if falling then
            yield_n_times(2)
        end
        for_all_tiles(function(y,x)
            if board[y][x] != empty then
                if block_can_fall_right(y,x) then
                    move_piece(y, x, y-1, x_for_next_row(y,x)+1)
                    falling=true
                end
            end
        end)
        if falling then
            yield_n_times(2)
        end
    end
end

function find_blocks_to_delete()
    local blocks_to_delete = {} -- y,x pairs
    for_all_tiles(function(y,x)
        local current_piece = board[y][x]
        if current_piece != empty then
            local one_row_up_x = x_for_next_row(y, x)

            -- square!
            if current_piece == board[y+1][one_row_up_x] and current_piece == board[y+1][one_row_up_x+1] and current_piece == board[y+2][x] then
                add(blocks_to_delete,{y=y,x=x})
                add(blocks_to_delete,{y=y+1,x=one_row_up_x})
                add(blocks_to_delete,{y=y+1,x=one_row_up_x+1})
                add(blocks_to_delete,{y=y+2,x=x})
            end
            -- line going left!
            if current_piece == board[y+1][one_row_up_x] and current_piece == board[y+2][x-1] then
                add(blocks_to_delete,{y=y,x=x})
                add(blocks_to_delete,{y=y+1,x=one_row_up_x})
                add(blocks_to_delete,{y=y+2,x=x-1})
            end
            -- line going right!
            if current_piece == board[y+1][one_row_up_x+1] and current_piece == board[y+2][x+1] then
                add(blocks_to_delete,{y=y,x=x})
                add(blocks_to_delete,{y=y+1,x=one_row_up_x+1})
                add(blocks_to_delete,{y=y+2,x=x+1})
            end
        end
    end)
    return blocks_to_delete
end

function hit_bottom()
    hard_dropping=false
    combo_size = 0
    y_shift-=shimmy_coefficient/2
    sfx(11)

    blocks_clearing=cocreate(function()
        yield_n_times(3)
        let_pieces_settle()

        yield_n_times(3)
        local cleared_things=true -- todo this is a lie at this moment
        local scored_this_turn=0
        while cleared_things do
            cleared_things=false

            local blocks_to_delete = find_blocks_to_delete()
            local cleared_this_iteration = 0 --todo this makes cleared_things pointless
            for b in all(blocks_to_delete) do
                cleared_things = true
                if board[b.y][b.x] != empty then
                    cleared_this_iteration+=1
                end
                board[b.y][b.x] = empty
            end

            if cleared_things then
                combo_size += 1
                local combo_multiplier = mid(1,combo_size,4)
                cleared += cleared_this_iteration
                scored_this_turn += combo_size*calculate_points_scored(cleared_this_iteration, level)
                if #blocks_to_delete < 4 then
                    small_clear_sound()
                else
                    big_clear_sound()
                end
            end

            yield_n_times(3)
            if cleared_things then
                let_pieces_settle()
            end
        end

        if combo_size > 1 then
            drawing_combo_text=cocreate(draw_combo_text)
            yield_n_times(2)
            combo_reward_sound()
        end

        score += scored_this_turn
        level = flr(cleared/30)
        if level == 15 then
            game_state = "won"
            music(10)
        else
            new_player_quad()
        end
    end)
end

function for_all_tiles(callback)
    for y = 1, board_height do
        for x = 1, board_width do
            if board[y][x] != wall then
                callback(y, x)
            end
        end
    end
end

function random_block()
    local val = flr(rnd(4))
    if val == 0 then
        return white_block
    elseif val == 1 then
        return red_block
    elseif val == 2 then
        return yellow_block
    end
    return blue_block
end

function new_board()
    local grid = {}
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
    -- TODO should still be cleaned up more
    return (row_at_beginning_or_end(y, 1) and x != 4) or
        (row_at_beginning_or_end(y, 2) and (x < 4 or 5 < x)) or
        (row_at_beginning_or_end(y, 3) and (x < 3 or 5 < x)) or
        (row_at_beginning_or_end(y, 4) and (x < 3 or 6 < x)) or
        (row_at_beginning_or_end(y, 5) and (x < 2 or 6 < x)) or
        (row_at_beginning_or_end(y, 6) and (x < 2 or 7 < x)) or
        (is_odd(y) and x == board_width)
end

function is_odd(num)
    return num % 2 != 0
end

function row_at_beginning_or_end(real, expected)
    return real == expected or real == board_height-expected+1
end

-- configuration options
function turn_on_shadow()
    display_shadow=true
    menuitem(1, "hide shadow", turn_off_shadow)
end

function turn_off_shadow()
    display_shadow=false
    menuitem(1, "show shadow", turn_on_shadow)
end


#include audio.lua
#include movement.lua
#include fancy-printing.lua
#include player-quad.lua
#include update.lua
#include juice.lua
#include draw.lua

__gfx__
00000000007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007007000070080880800aaaaaa00cc00cc001111110000606000000000000000000000000000000000000000000000000000000000000000000000000000
000770007000070080880800aaaaaa00cc00cc001111110000066000000000000000000000000000000000000000000000000000000000000000000000000000
0007700007007000080080000aaaa0000cccc0000111100000666000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700000000007000000000000070000000000077000000000000700000000000700000000700000700000000000000007000000700000000070000000000000
07070000000007000000000000700000000000700700000000000700000000000700000000700000700000000000000007000000700000000070000000000000
07007000000007000000000007000000000007000070000000000700000000000700000000700000770000000000000077000000700000000707000000000000
07000700000007000000000070000000000070000007000000000700000000000700000000700000770000000000000077000000700000000707000000000000
07000070000007000000000700000000000700000000700000000700000000000700000000700000707000000000000707000000700000000707000000000000
07000007000007000000007000000000007000000000070000000700000000000700000000700000707000000000000707000000700000000707000000000000
07000007000007000000070000000000070000000000007000000700000000000700000000700000700700000000007007000000700000007000700000000000
07000070000007000000700000000000700000000000000700000700000000000700000000700000700700000000007007000000700000007000700000000000
07000700000007000007000000000007000000000000000070000700000000000700000000700000700070000000070007000000700000007000700000000000
07007000000007000007000000000007000000000000000070000700000000000700000000700000700070000000070007000000700000070000070000000000
07070000000007000000700000000000700000000000000700000700000000000700000000700000700007000000700007000000700000070000070000000000
07700000000007000000070000000000070000000000007000000700000000000700000000700000700007000000700007000000700000077777770000000000
07000000000007000000007000000000007000000000070000000700000000000700000000700000700000700007000007000000700000700000007000000000
07000000000007000000000700000000000700000000700000000700000000000700000000700000700000700007000007000000700000700000007000000000
07000000000007000000000070000000000070000007000000000700000000000770000007700000700000070070000007000000700000700000007000000000
07000000000007000000000007000000000007000070000000000700000000000070000007000000700000070070000007000000700000700000007000000000
07000000000007000000000000700000000000700700000000000700000000000077000077000000700000007700000007000000700007000000000700000000
07000000000007000000000000070000000000077000000000000777777770000007777770000000700000000000000007000000700007000000000700000000
__sfx__
010f00000c05511005130051300514005130050e00500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
011000000c05500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001105500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00001505500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001c05500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001805500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001105500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001305500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00001505500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
011000001d05500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
011000001a05500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000056300403005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503
010c0000000550e0510e050000000c055000001104513041130400000010065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0000000550e0510e040000000c045000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000505513031130300000010035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b0000000550e0510e050000000c04500000110451303113030000001005500000180651c0611c0600000018065000001306218060180501802018015000000000000000000000000000000000000000000000
010d00001101411020110201101500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00001501415010130101301500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001701418020180221801200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002401500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002601200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00002401200000007000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b0000150341502013025000000000000000000000000000000000000000000000000001302013025000000000000000000001c0201c0201c0101c015000000000000000000000000000000000000000000000
000b0000170341802018025000000000000000000000000000000000000000000000000001802018022000000000000000000002b0202b0102b01500000000000000000000000000000000000000000000000000
01130000000550e0510e0430d0410d0430c0410c0430b0410b0530a0510a053090510905308051080530705106051060510605106051060511205113053000001604217060000000000000000000000000000000
__music__
04 00021344
04 0a085844
04 02035344
04 00050715
04 01020315
04 03050415
04 10111244
04 0d111244
04 0e111244
04 10110d44
04 0f161744

