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

function move_sound()
    sfx(flr(rnd(number_of_sounds+1)))
end