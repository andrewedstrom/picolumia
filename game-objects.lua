-->8
-- game object factories

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

    if board[p3.y][p3.x] ~= empty or board[p2.y][p2.x] ~= empty or board[p1.y][p1.x] ~= empty or board[p0.y][p0.x] ~= empty or (not block_can_fall_left(p1.y, p1.x) and not block_can_fall_right(p2.y, p2.x)) then
        sfx(24)
        game_state = "gameover"
    end
    board[p3.y][p3.x] = next_quad.p3
    board[p2.y][p2.x] = next_quad.p2
    board[p1.y][p1.x] = next_quad.p1
    board[p0.y][p0.x] = next_quad.p0

    make_next_quad()
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
            if currently_clearing_blocks() or game_state ~= "playing" then
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
    return (row_at_beginning_or_end(y, 1) and x ~= 4) or
        (row_at_beginning_or_end(y, 2) and (x < 4 or 5 < x)) or
        (row_at_beginning_or_end(y, 3) and (x < 3 or 5 < x)) or
        (row_at_beginning_or_end(y, 4) and (x < 3 or 6 < x)) or
        (row_at_beginning_or_end(y, 5) and (x < 2 or 6 < x)) or
        (row_at_beginning_or_end(y, 6) and (x < 2 or 7 < x)) or
        (is_odd(y) and x == board_width)
end

function row_at_beginning_or_end(real, expected)
    return real == expected or real == board_height-expected+1
end