function x_for_next_row(current_y, current_x)
    if is_odd(current_y) then return current_x end
    return current_x - 1
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

function move_down(next_y, next_x)
    local p0 = player:player0()
    local p1 = player:player1()
    local p2 = player:player2()
    local p3 = player:player3()

    local next_y = player.y - 2
    local next_x = player.x

    if next_y > 0 and board[next_y][next_x] == empty then
        move_piece(p0.y, p0.x, next_y, next_x)
        move_piece(p1.y, p1.x, next_y + 1, p1.x)
        move_piece(p2.y, p2.x, next_y + 1, p2.x)
        move_piece(p3.y, p3.x, next_y + 2, next_x)

        player.x = next_x
        player.y = next_y
    elseif next_y < 0 then
        hit_bottom()
    else
        local next_action = hit_bottom
        if can_move_left(p0, p1) and can_move_right(p0, p2) then
            if last_direction_moved == "right" then
                next_action = move_right
            else
                next_action = move_left
            end
        elseif can_move_left(p0, p1) then
            next_action = move_left
        elseif can_move_right(p0, p2) then
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

    local next_y = p0.y - 1
    local next_x = x_for_next_row(p0.y, p0.x)
    local one_row_up_x = x_for_next_row(p0.y + 1, next_x)

    if can_move_left(p0, p1) then
        move_piece(p0.y, p0.x, next_y, next_x)
        move_piece(p1.y, p1.x, next_y + 1, one_row_up_x)
        move_piece(p2.y, p2.x, next_y + 1, one_row_up_x + 1)
        move_piece(p3.y, p3.x, next_y + 2, next_x)

        player.x = next_x
        player.y = next_y
        last_direction_moved = "left"
        return true
    elseif not can_move_right(p0, p2) then
        hit_bottom()
        return false
    end
end

function can_move_left(p0, p1)
    return p0.y - 1 > 0 and block_can_fall_left(p0.y, p0.x) and
               block_can_fall_left(p1.y, p1.x)
end

function block_can_fall_left(old_y, old_x)
    local next_x = x_for_next_row(old_y, old_x)
    local next_y = old_y - 1
    if next_y < 1 or next_x < 1 then return false end

    return board[next_y][next_x] == empty
end

function move_right() -- todo combine into one method with move_left
    local p0 = player:player0()
    local p1 = player:player1()
    local p2 = player:player2()
    local p3 = player:player3()

    local next_y = p0.y - 1
    local next_x = x_for_next_row(p0.y, p0.x) + 1
    local one_row_up_x = x_for_next_row(p0.y + 1, next_x)

    if can_move_right(p0, p2) then
        move_piece(p0.y, p0.x, next_y, next_x)
        move_piece(p1.y, p1.x, next_y + 1, one_row_up_x)
        move_piece(p2.y, p2.x, next_y + 1, one_row_up_x + 1)
        move_piece(p3.y, p3.x, next_y + 2, next_x)

        player.x = next_x
        player.y = next_y
        last_direction_moved = "right"
        return true
    elseif not can_move_left(p0, p1) then
        hit_bottom()
        return false
    end
end

function can_move_right(p0, p2)
    return p0.y - 1 > 0 and block_can_fall_right(p0.y, p0.x) and
               block_can_fall_right(p2.y, p2.x)
end

function block_can_fall_right(old_y, old_x)
    local next_x = x_for_next_row(old_y, old_x) + 1
    local next_y = old_y - 1
    if next_y < 1 or next_x > board_width then return false end
    return board[next_y][next_x] == empty
end

function move_piece(old_y, old_x, new_y, new_x)
    board[new_y][new_x] = board[old_y][old_x]
    board[old_y][old_x] = empty
end
