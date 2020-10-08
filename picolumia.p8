pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- picolumia
-- by andrew edstrom
local board
local player
local next_piece
local speed_timer
local speed
local last_direction_moved -- "right" or "left"
local blocks_clearing
local game_state -- "playing", "gameover", "menu", "won"
local hard_dropping

-- values to display in hud
local cleared
local score
local level
local seconds_elapsed
local seconds_timer

-- piece types
local white = 8
local red = 16
local yellow = 24
local blue = 32
local empty = 40
local wall = -1
local number_of_sounds=10

-- board constants
local board_display_x_offset = 25 -- Used to center the board
local board_height = 27 -- must be odd for math to work out
local board_width = 8
local bottom = 120
local piece_width = 8
local piece_height = 4
local sprite_size = 6

-- set up palette
function setup_palette()
    _pal={0,129,136,140,1,5,6,7,8,135,10,3,12,13,133,134}
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
    make_next_piece()
    new_player_quad()
    last_direction_moved="right"
    speed_timer = 0
    seconds_timer = 0
    seconds_elapsed = 0
    speed = 27
    cleared = 0
    level = 0
    score = 0
    hard_dropping = false
end

function _update()
    if game_state == "gameover" or game_state == "menu" then
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
    elseif btnp(1) then
        just_moved=move_right()
    elseif btn(3) then
        hard_dropping=true
        move_down()
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
    rect(0,0,127,127,5) -- todo remove

    if game_state == "menu" then
        draw_board()
        draw_menu()
    else
        cls()
        draw_board()
        next_piece:draw()
        draw_hud()
        if game_state == "gameover" then
            centered_print("game over", 64, 1, 7, 1)
        elseif game_state == "won" then
            centered_print("you win!!!", 64, 1, 7, 1)
        end
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
        shadow = player_shadow()
    end

    for_all_tiles(function(y,x)
        local x_loc=x*piece_width + board_display_x_offset
        if is_odd(y) then
            x_loc += piece_width/2
        end
        local y_loc=bottom-y*piece_height
        if board[y][x] != wall then
            -- change colors for indicator of where piece would fall
            local sprite = board[y][x]

            if shadow and shadow:is_in_shadow(y,x) and not currently_clearing_blocks() then
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
end

function draw_hud()
    -- todo just use magic numbers when you run out of tokens
    local right_side_x=piece_width*board_width+piece_width+board_display_x_offset
    local y_loc=45

    -- left side
    print("time", board_display_x_offset-9, y_loc, 7)
    print(display_time(), board_display_x_offset-13, y_loc+8, 7)

    print("level", board_display_x_offset-13, y_loc+26,7)
    local level_num_x_pos = board_display_x_offset+3
    if level > 9 then
        level_num_x_pos -= 4
    end
    print(level, level_num_x_pos, y_loc+34,7)

    -- right side
    print("cleared",right_side_x,y_loc,7)
    print(cleared, right_side_x,y_loc+8,7)

    print("score", right_side_x, y_loc+26,7)
    print(score, right_side_x, y_loc+34,7)
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

function player_shadow()
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
        if can_move_left() and can_move_right() then
            if last_direction_moved == "right" then
                next_action = move_right
            else
                next_action = move_left
            end
        elseif can_move_left() then
            next_action = move_left
        elseif can_move_right() then
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

    if can_move_left() then
        move_piece(p0.y,p0.x,next_y,next_x)
        move_piece(p1.y,p1.x,next_y+1,one_row_up_x)
        move_piece(p2.y,p2.x,next_y+1,one_row_up_x+1)
        move_piece(p3.y,p3.x,next_y+2,next_x)

        player.x = next_x
        player.y = next_y
        last_direction_moved = "left"
        return true
    elseif not can_move_right() then
        hit_bottom()
        return false
    end
end

function can_move_left()
    local p1 = player:player1()
    return player.y-1 > 0 and block_can_fall_left(player.y,player.x) and block_can_fall_left(p1.y,p1.x)
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

    if can_move_right() then
        move_piece(p0.y,p0.x,next_y,next_x)
        move_piece(p1.y,p1.x,next_y+1,one_row_up_x)
        move_piece(p2.y,p2.x,next_y+1,one_row_up_x+1)
        move_piece(p3.y,p3.x,next_y+2,next_x)

        player.x = next_x
        player.y = next_y
        last_direction_moved = "right"
        return true
    elseif not can_move_left() then
        hit_bottom()
        return false
    end
end

function can_move_right()
    local p2 = player:player2()
    return player.y-1 > 0 and block_can_fall_right(player.y,player.x) and block_can_fall_right(p2.y,p2.x)
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

function hit_bottom()
    hard_dropping=false
    blocks_clearing=cocreate(function()
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
                yield()
                for_all_tiles(function(y,x)
                    if board[y][x] != empty then
                        if block_can_fall_right(y,x) then
                            move_piece(y, x, y-1, x_for_next_row(y,x)+1)
                            falling=true
                        end
                    end
                end)

                yield()
            end
        end

        let_pieces_settle()

        yield()
        yield()
        yield()
        local cleared_things=true -- todo this is a lie at this moment
        while cleared_things do
            cleared_things=false

            local blocks_to_delete ={} -- y,x pairs
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

            local cleared_this_iteration = 0 --todo this makes cleared_things pointless
            for b in all(blocks_to_delete) do
                cleared_things = true
                if board[b.y][b.x] != empty then
                    cleared_this_iteration+=1
                end
                board[b.y][b.x] = empty
            end

            if cleared_things then
                cleared += cleared_this_iteration
                score += calculate_points_scored(cleared_this_iteration, level)
                if #blocks_to_delete < 4 then
                    small_clear_sound()
                elseif #blocks_to_delete < 6 then
                    medium_clear_sound()
                else
                    big_clear_sound()
                end
            end

            yield()
            yield()
            yield()
            if cleared_things then
                let_pieces_settle()
            end
        end

        level = flr(cleared/30)

        if level == 15 then
            game_state = "won"
        else
            new_player_quad()
        end
    end)
end

function small_clear_sound()
    local clear_sounds={0,1,2}
    music(clear_sounds[flr(rnd(#clear_sounds))+1])
end

function medium_clear_sound()
    local clear_sounds={4}
    music(clear_sounds[flr(rnd(#clear_sounds))+1])
end

function big_clear_sound()
    local clear_sounds={3}
    music(clear_sounds[flr(rnd(#clear_sounds))+1])
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
    board[p3.y][p3.x] = next_piece.p3
    board[p2.y][p2.x] = next_piece.p2
    board[p1.y][p1.x] = next_piece.p1
    board[p0.y][p0.x] = next_piece.p0

    make_next_piece()
end

function make_next_piece()
    local p0=random_piece()
    local p1=random_piece()
    local p2=random_piece()
    local p3=random_piece()
    while p0 == p1 and p1 == p2 and p2 == p3 do
        p3=random_piece()
    end
    next_piece={
        p0=p0,
        p1=p1,
        p2=p2,
        p3=p3,
        draw=function(self)
            local x_loc=board_display_x_offset
            local y_loc=bottom-board_height*piece_height
            sspr(p3,0,sprite_size,sprite_size,x_loc,y_loc)
            sspr(p2,0,sprite_size,sprite_size,x_loc+piece_width/2,y_loc+piece_height)
            sspr(p1,0,sprite_size,sprite_size,x_loc-piece_width/2,y_loc+piece_height)
            sspr(p0,0,sprite_size,sprite_size,x_loc,y_loc+piece_height*2)
        end
    }
end

function random_piece()
    local val = flr(rnd(4))
    if val == 0 then
        return white
    elseif val == 1 then
        return red
    elseif val == 2 then
        return yellow
    end
    return blue
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

__gfx__
00000000007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007007000070080880800aaaaaa00cc00cc001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770007000070080880800aaaaaa00cc00cc001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
04 00024444
04 0a084344
04 02034344
04 00050706
04 01020344

