function yield_n_times(n)
    local i
    for i=1,n do
        yield()
    end
end

function calculate_points_scored(blocks_cleared)
    return (level+1)*((blocks_cleared-2)^2)
end

function let_pieces_settle()
    --todo do this as a coroutine too
    local falling=true
    while falling do
        falling=false
        -- todo make this happen over multiple frames
        for_all_tiles(function(y, x)
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
        for_all_tiles(function(y, x)
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
                spawn_particles(b.y,b.x)
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