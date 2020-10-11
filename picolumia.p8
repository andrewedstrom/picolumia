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

-- set up palette
function setup_palette()
    _pal={0,129,136,140,1,5,6,7,8,135,10,131,12,13,133,134}
    for i,c in pairs(_pal) do
        pal(i-1,c,1)
    end
end

function _init()
    game_state="menu"
    board=new_board()
    setup_palette()
end

function start_game()
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

function _update()
    if game_state == "menu" then
        update_menu()
    elseif game_state == "playing" then
        update_game()
    end
end

function update_game()
    update_timers()

    if currently_clearing_blocks() then
        coresume(blocks_clearing)
    elseif hard_dropping then
        move_down()
    else
        if speed_timer >= (speed - level) then
            tick()
            speed_timer = 0
        end
        handle_input()
    end
end

function currently_clearing_blocks()
    return blocks_clearing and costatus(blocks_clearing) != 'dead'
end

function update_timers()
    speed_timer += 1
    seconds_timer += 1

    if seconds_timer == 30 then
        seconds_elapsed += 1
        seconds_timer = 0
    end
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

function update_menu()
    if btn(4) or btn(5) then
        game_state = "playing"
        start_game()
    end
end

function _draw()
    cls()
    camera()
    rect(0,0,127,127,5) -- todo remove

    if game_state == "menu" then
        draw_board()
        draw_menu()
    else
        draw_hud()
        if drawing_combo_text and costatus(drawing_combo_text) != dead then
            coresume(drawing_combo_text)
        end

        doshake()
        draw_board()
    end

    if game_state == "gameover" then
        print_in_box("game over", board_left+40, 60)
    elseif game_state == "won" then
        print_in_box("you win!!!", board_left+40, 60)
    end
end

function draw_menu()
    sspr(1,8,121,25,5,45)

    centered_print("press \x97 to begin", 64, 103,7,1)
end

-- The board is organized with 1,1 as the bottom left corner
-- every other row is drawn shifted right by a half position
-- the diamond shape is made by setting the out-of-bounds spaces to "wall"
function draw_board()
    local shadow
    if player then
        shadow = player_quad_shadow()
    end

    for_all_tiles(function(y,x)
        local y_loc, x_loc = get_screen_position_for_block(y,x)
        if board[y][x] != wall then
            local sprite = board[y][x]

            if sprite == empty and shadow and shadow:is_in_shadow(y,x) and not currently_clearing_blocks() then
                -- switch block colors to block shadow colors
                pal()
                pal(12, 3)
                pal(8, 2)
                pal(7, 6)
                pal(10, 9)
                sprite = shadow:get_corresponding_sprite(y,x)
            end


            sspr(sprite,0,sprite_size,sprite_size,x_loc,y_loc)
            pal()
            setup_palette()
        end
    end)

    if shadow then
        shadow:draw_slide_indicator_arrow()
    end
    draw_board_outline()
end

function get_screen_position_for_block(y,x)
    local x_loc=x*piece_width + board_left
    if is_odd(y) then
        x_loc += piece_width/2
    end
    local y_loc=bottom-y*piece_height
    return y_loc, x_loc
end

function draw_board_outline()
    -- draw outline of board
    color(board_outline_color)
    local center_point_x=board_left+38
    local bottom_corner_y=bottom-28
    local upper_corner_y=bottom-79
    local bottom_point_y=bottom+5

    -- left side
    local left_side_line_x=board_left+5
    line(center_point_x, bottom_point_y, left_side_line_x, bottom_corner_y)
    line(left_side_line_x, upper_corner_y)
    line(center_point_x, bottom-board_height*piece_height-4)

    -- right side
    local right_side_line_x=board_left+board_width*piece_width+8
    line(center_point_x+1, bottom-board_height*piece_height-4, right_side_line_x, upper_corner_y)
    line(right_side_line_x, bottom_corner_y)
    line(center_point_x+1, bottom_point_y)
end

function draw_hud()
    local right_side_x=board_left+84
    local y_loc=8

    color(7)
    print("time",right_side_x, y_loc)
    print(display_time(), right_side_x, y_loc+8)

    print("level", right_side_x, y_loc+24)
    print(level.."/15", right_side_x, y_loc+32)

    print("cleared",right_side_x,y_loc+48)
    print(cleared, right_side_x,y_loc+56)

    print("score", right_side_x, y_loc+72)
    print(score, right_side_x, y_loc+80)

    local next_quad_y = y_loc+96
    local next_quad_x = right_side_x +piece_width/2
    sspr(next_quad.p3,0,sprite_size,sprite_size,next_quad_x,next_quad_y)
    sspr(next_quad.p2,0,sprite_size,sprite_size,next_quad_x+piece_width/2,next_quad_y+piece_height)
    sspr(next_quad.p1,0,sprite_size,sprite_size,next_quad_x-piece_width/2,next_quad_y+piece_height)
    sspr(next_quad.p0,0,sprite_size,sprite_size,next_quad_x,next_quad_y+piece_height*2)
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

-- Moving blocks
function rotate_clockwise()
    local p0 = player:player0()
    local p1 = player:player1()
    local p2 = player:player2()
    local p3 = player:player3()

    local tmp = board[p0.y][p0.x]
    board[p0.y][p0.x] = board[p2.y][p2.x]
    board[p2.y][p2.x] = board[p3.y][p3.x]
    board[p3.y][p3.x] = board[p1.y][p1.x]
    board[p1.y][p1.x] = tmp
end

function rotate_counter_clockwise()
    local p0 = player:player0()
    local p1 = player:player1()
    local p2 = player:player2()
    local p3 = player:player3()

    local tmp = board[p0.y][p0.x]
    board[p0.y][p0.x] = board[p1.y][p1.x]
    board[p1.y][p1.x] = board[p3.y][p3.x]
    board[p3.y][p3.x] = board[p2.y][p2.x]
    board[p2.y][p2.x] = tmp
end

function player_quad_shadow()
    local s0 = player:player0()
    local s1 = player:player1()
    local s2 = player:player2()
    local s3 = player:player3()

    local next_y=s0.y-2
    local next_x=s0.x

    while next_y > 0 and board[next_y][next_x] == empty do
        s0={y=next_y, x=next_x}
        s1.y=next_y+1
        s2.y=next_y+1
        s3={y=next_y+2, x=next_x}

        next_y=s0.y-2
        next_x=s0.x
    end

    return {
        s0=s0,
        s1=s1,
        s2=s2,
        s3=s3,
        is_in_shadow=function(self,y,x)
            s0 = self.s0
            s1 = self.s1
            s2 = self.s2
            s3 = self.s3
            return (y == s0.y and x == s0.x) or (y == s1.y and x == s1.x) or (y == s2.y and x == s2.x) or (y == s3.y and x == s3.x)
        end,
        get_corresponding_sprite=function(self,y,x)
            local s0 = self.s0
            local s1 = self.s1
            local s2 = self.s2
            local s3 = self.s3
            local p0 = player:player0()
            local p1 = player:player1()
            local p2 = player:player2()
            local p3 = player:player3()

            if y == s0.y and x == s0.x then
                return board[p0.y][p0.x]
            elseif y == s1.y and x == s1.x then
                return board[p1.y][p1.x]
            elseif y == s2.y and x == s2.x then
                return board[p2.y][p2.x]
            end
            return board[p3.y][p3.x]
        end,
        draw_slide_indicator_arrow=function(self)
            if currently_clearing_blocks() then
                return
            end

            local s0 = self.s0
            local s1 = self.s1
            local s2 = self.s2

            local next_x=x_for_next_row(s0.y, s0.x)
            local next_y=s0.y-1
            local arrow_sprite=6

            local right = can_move_right(s0, s2)
            local left = can_move_left(s0, s1)

            -- todo this logic is duplicated somewhere else, could dedupe to save tokens
            if left and right then
                if last_direction_moved == "right" then
                    -- if they're moving right, they would slide right
                    left=false
                else
                    -- and vice versa
                    right=false
                end
            end

            if right then
                -- get screen position to draw arrow
                local y_pos,x_pos=get_screen_position_for_block(next_y,next_x+1)
                spr(arrow_sprite,x_pos+2,y_pos-2)
            end

            if left then
                -- get screen position to draw arrow
                local y_pos,x_pos=get_screen_position_for_block(next_y,next_x)
                spr(arrow_sprite,x_pos-3,y_pos-2,1,1,true,false)
            end
        end
    }
end

function move_down(next_y,next_x)
    local p0 = player:player0()
    local p1 = player:player1()
    local p2 = player:player2()
    local p3 = player:player3()

    local next_y=player.y-2
    local next_x=player.x

    if next_y > 0 and board[next_y][next_x] == empty then
        move_piece(p0.y,p0.x,next_y,next_x)
        move_piece(p1.y,p1.x,next_y+1,p1.x)
        move_piece(p2.y,p2.x,next_y+1,p2.x)
        move_piece(p3.y,p3.x,next_y+2,next_x)

        player.x = next_x
        player.y = next_y
    elseif next_y < 0 then
        hit_bottom()
    else
        local next_action = hit_bottom
        if can_move_left(p0,p1) and can_move_right(p0,p2) then
            if last_direction_moved == "right" then
                next_action = move_right
            else
                next_action = move_left
            end
        elseif can_move_left(p0,p1) then
            next_action = move_left
        elseif can_move_right(p0,p2) then
            next_action = move_right
        end
        next_action()
    end
end

function move_left()
    local p0 = player:player0()
    local p1 = player:player1()
    local p2 = player:player2()
    local p3 = player:player3()

    local next_y=p0.y-1
    local next_x=x_for_next_row(p0.y, p0.x)
    local one_row_up_x = x_for_next_row(p0.y+1,next_x)

    if can_move_left(p0,p1) then
        move_piece(p0.y,p0.x,next_y,next_x)
        move_piece(p1.y,p1.x,next_y+1,one_row_up_x)
        move_piece(p2.y,p2.x,next_y+1,one_row_up_x+1)
        move_piece(p3.y,p3.x,next_y+2,next_x)

        player.x = next_x
        player.y = next_y
        last_direction_moved = "left"
        return true
    elseif not can_move_right(p0,p2) then
        hit_bottom()
        return false
    end
end

function can_move_left(p0, p1)
    return p0.y-1 > 0 and block_can_fall_left(p0.y,p0.x) and block_can_fall_left(p1.y,p1.x)
end

function block_can_fall_left(old_y,old_x)
    local next_x = x_for_next_row(old_y, old_x)
    local next_y = old_y-1
    if next_y < 1 or next_x < 1 then
        return false
    end

    return board[next_y][next_x] == empty
end

function move_right() --todo combine into one method with move_left
    local p0 = player:player0()
    local p1 = player:player1()
    local p2 = player:player2()
    local p3 = player:player3()

    local next_y=p0.y-1
    local next_x=x_for_next_row(p0.y, p0.x)+1
    local one_row_up_x = x_for_next_row(p0.y+1,next_x)

    if can_move_right(p0,p2) then
        move_piece(p0.y,p0.x,next_y,next_x)
        move_piece(p1.y,p1.x,next_y+1,one_row_up_x)
        move_piece(p2.y,p2.x,next_y+1,one_row_up_x+1)
        move_piece(p3.y,p3.x,next_y+2,next_x)

        player.x = next_x
        player.y = next_y
        last_direction_moved = "right"
        return true
    elseif not can_move_left(p0, p1) then
        hit_bottom()
        return false
    end
end

function can_move_right(p0,p2)
    return p0.y-1 > 0 and block_can_fall_right(p0.y,p0.x) and block_can_fall_right(p2.y,p2.x)
end

function block_can_fall_right(old_y,old_x)
    local next_x = x_for_next_row(old_y, old_x)+1
    local next_y = old_y-1
    if next_y < 1 or next_x > board_width then
        return false
    end
    return board[next_y][next_x] == empty
end

function move_piece(old_y,old_x,new_y,new_x)
    board[new_y][new_x] = board[old_y][old_x]
    board[old_y][old_x] = empty
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
        yield_n_times(2)
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

function draw_combo_text()
    local x_loc=board_left-5
    local y_loc=8
    local message = combo_size.."x combo!"

    local i
    for i=1,20 do
        if i % 5 == 0 then
            y_loc -= 1
        end
        print(message,x_loc,y_loc,11)
        yield()
    end
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

function small_clear_sound()
    local clear_sounds={0,1,2}
    music(clear_sounds[flr(rnd(#clear_sounds))+1])
end

function big_clear_sound()
    local clear_sounds={3,4,5}
    music(clear_sounds[flr(rnd(#clear_sounds))+1])
end

function combo_reward_sound()
    local combo_sounds={6,7,8,9}
    music(combo_sounds[flr(rnd(#combo_sounds))+1])
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

-- player is represented as the bottom of the falling quad
--     player3
-- player1  player2
--     player0
function new_player_quad()
    player={
        y=board_height-2,
        x=4,
        player0=function(self)
            return {
                x=self.x,
                y=self.y
            }
        end,
        player1=function(self) --todo get all of these back in one method call
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
        end,
        is_player_piece=function(self, y, x)
            local p3 = self:player3()
            local p2 = self:player2()
            local p1 = self:player1()
            local p0 = self:player0()

            return (x == p0.x or x == p1.x or x == p2.x or x == p3.x) and
                (y == p0.y or y == p1.y or y == p2.y or y == p3.y)
        end
    }
    -- todo add function to player to multi return all current pieces
    local p3 = player:player3()
    local p2 = player:player2()
    local p1 = player:player1()
    local p0 = player:player0()

    if board[p3.y][p3.x] != empty or board[p2.y][p2.x] != empty or board[p1.y][p1.x] != empty or board[p0.y][p0.x] != empty then
        game_state = "gameover"
    end
    board[p3.y][p3.x] = next_quad.p3
    board[p2.y][p2.x] = next_quad.p2
    board[p1.y][p1.x] = next_quad.p1
    board[p0.y][p0.x] = next_quad.p0

    make_next_quad()
end

function make_next_quad()
    local p0=random_block()
    local p1=random_block()
    local p2=random_block()
    local p3=random_block()
    while p0 == p1 and p1 == p2 and p2 == p3 do
        p3=random_block()
    end
    next_quad={
        p0=p0,
        p1=p1,
        p2=p2,
        p3=p3
    }
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

function x_for_next_row(current_y, current_x)
    if is_odd(current_y) then
        return current_x
    end
    return current_x-1
end

-- fancy printing
function print_in_box(message,x,y)
    local pico8_letter_width = 4
    local message_width_px = #message*pico8_letter_width
    local box_left = x-message_width_px/2-pico8_letter_width
    local box_right = x+message_width_px/2+1
    local box_top = y-pico8_letter_width
    local box_bottom = y+pico8_letter_width*2
    local box_color = 6

    rectfill(box_left+2,box_top,box_right-2,box_bottom,box_color)
    rectfill(box_left+1,box_top+1,box_right-1,box_bottom-1,box_color)
    rectfill(box_left,box_top+2,box_right,box_bottom-2,box_color)

    centered_print(message, x, y, 7, 0)
end

function centered_print(text,x,y,col,outline_col)
    outlined_print(text, x-#text*2, y, col, outline_col)
end

function outlined_print(text,x,y,col,outline_col)
    print(text,x-1,y,outline_col)
    print(text,x+1,y,outline_col)
    print(text,x,y-1,outline_col)
    print(text,x,y+1,outline_col)

    print(text,x,y,col)
end

-- game feel thiccness
function doshake()
    local x_pos = flr(x_shift)
    if x_shift < 0 then
        x_pos = ceil(x_shift)
    end

    camera(x_pos,y_shift)
    x_shift *= shimmy_degredation_rate
    y_shift *= shimmy_degredation_rate

    if abs(x_shift) < minimum_shimmy_threshold then
        x_shift = 0
    end
    if abs(y_shift) < minimum_shimmy_threshold then
        y_shift = 0
    end
end

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
