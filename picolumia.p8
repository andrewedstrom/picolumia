pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

local board
local player
local next_quad
local timer
local speed
local last_direction_moved -- "right" or "left"
local blocks_clearing

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
    new_player_quad()
    last_direction_moved="right"

    timer = 0
    speed = 30
end

function _update()
    timer += 1
    if timer == speed then
        tick()
        timer = 0
    end

    if blocks_clearing and costatus(blocks_clearing) != 'dead' then
        coresume(blocks_clearing)
    else
        -- handle input
        if btnp(0) then
            move_left()
            timer = 0
        elseif btnp(1) then
            move_right()
            timer = 0
        elseif btn(3) then
            move_down()
        end
        if btnp(4) then
            rotate_counter_clockwise()
        elseif btnp(5) then
            rotate_clockwise()
        end
    end
end

function _draw()
    cls()
    rect(0,0,127,127,5)

    draw_board()
    draw_next_piece()
end

-- The board is organized with 1,1 as the bottom left corner
-- every other row is drawn shifted right by a half position
-- the diamond shape is made by setting the out-of-bounds spaces to "wall"
function draw_board()
    for_all_tiles(function(y,x)
        local x_loc=x*piece_width
        if is_odd(y) then
            x_loc += piece_width/2
        end
        local y_loc=bottom-y*piece_height
        if board[y][x] != wall then
            sspr(board[y][x],0,sprite_size,sprite_size,x_loc,y_loc)
        end
    end)
end

function draw_next_piece()
    local x_loc=piece_width*board_width+piece_width
    local y_loc=bottom-board_height*piece_height
    sspr(next_quad.p0,0,sprite_size,sprite_size,x_loc,y_loc)
    sspr(next_quad.p1,0,sprite_size,sprite_size,x_loc-piece_width/2,y_loc+piece_height)
    sspr(next_quad.p2,0,sprite_size,sprite_size,x_loc+piece_width/2,y_loc+piece_height)
    sspr(next_quad.p3,0,sprite_size,sprite_size,x_loc,y_loc+piece_height*2)
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

function move_down(next_y,next_x)
    local old_y=player.y
    local old_x=player.x
    local next_y=player.y-2
    local next_x=player.x

    local p1 = player:player1()
    local p2 = player:player2()
    local p3 = player:player3()

    if next_y > 0 and board[next_y][next_x] == empty then
        move_piece(old_y,old_x,next_y,next_x)
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
    local old_y=player.y
    local old_x=player.x
    local next_y=old_y-1
    local next_x=x_for_next_row(old_y, old_x)
    local one_row_up_x = x_for_next_row(old_y+1,next_x)
    local p1 = player:player1()
    local p2 = player:player2()
    local p3 = player:player3()

    if can_move_left() then
        move_piece(old_y,old_x,next_y,next_x)
        move_piece(p1.y,p1.x,next_y+1,one_row_up_x)
        move_piece(p2.y,p2.x,next_y+1,one_row_up_x+1)
        move_piece(p3.y,p3.x,next_y+2,next_x)

        player.x = next_x
        player.y = next_y
        last_direction_moved = "left"
    elseif not can_move_right() then
        hit_bottom()
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
    local old_y=player.y
    local old_x=player.x
    local next_y=old_y-1
    local next_x=x_for_next_row(old_y, old_x)+1
    local one_row_up_x = x_for_next_row(old_y+1,next_x)
    local p1 = player:player1()
    local p2 = player:player2()
    local p3 = player:player3()

    if can_move_right() then
        move_piece(old_y,old_x,next_y,next_x)
        move_piece(p1.y,p1.x,next_y+1,one_row_up_x)
        move_piece(p2.y,p2.x,next_y+1,one_row_up_x+1)
        move_piece(p3.y,p3.x,next_y+2,next_x)

        player.x = next_x
        player.y = next_y
        last_direction_moved = "right"
    elseif not can_move_left() then
        hit_bottom()
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

function hit_bottom()
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
                        elseif block_can_fall_right(y,x) then
                            move_piece(y, x, y-1, x_for_next_row(y,x)+1)
                            falling=true
                        end
                    end
                end)

                yield()
                yield()
                yield()
                yield()
            end
        end

        let_pieces_settle()

        yield()
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

            for b in all(blocks_to_delete) do
                cleared_things = true
                board[b.y][b.x] = empty
            end
            yield()
            yield()
            yield()
            yield()
            if cleared_things then
                let_pieces_settle()
            end
        end

        new_player_quad()
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
        end
    }
    local p3 = player:player3()
    board[p3.y][p3.x] = random_piece()

    local p2 = player:player2()
    board[p2.y][p2.x] = random_piece()

    local p1 = player:player1()
    board[p1.y][p1.x] = random_piece()

    board[player.y][player.x] = random_piece()

    -- Don't allow all 4 pieces to be the same color
    while board[player.y][player.x] == board[p1.y][p1.x] and board[p1.y][p1.x] == board[p2.y][p2.x] and board[p2.y][p2.x] == board[p3.y][p3.x] do
        board[player.y][player.x] = random_piece()
    end

    next_quad=new_quad()
end

function new_quad()
    local p0=random_piece()
    local p1=random_piece()
    local p2=random_piece()
    local p3=random_piece()
    while p0 == p1 and p1 == p2 and p2 == p3 do
        p3=random_piece()
    end
    return {
        p0=p0,
        p1=p1,
        p2=p2,
        p3=p3
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

__gfx__
00000000007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007007000070080880800aaaaaa00cc00cc001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770007000070080880800aaaaaa00cc00cc001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700007007000080080000aaaa0000cccc0000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007700000088000000aa000000cc00000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000
