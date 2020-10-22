-->8
-- init functions

function _init()
    game_state = "menu"
    particles={}

    -- config
    turn_on_shadow()
    standard_rotation_mode()
end

function start_game()
    board = new_board()
    game_state = "playing"
    setup_palette()
    make_next_quad()
    new_player_quad()
    last_direction_moved = "right"
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
