-->8
-- configuration options
function turn_on_shadow()
    display_shadow = true
    menuitem(1, "hide shadow", turn_off_shadow)
end

function turn_off_shadow()
    display_shadow = false
    menuitem(1, "show shadow", turn_on_shadow)
end

function standard_rotation_mode()
    swap_rotation_buttons = false
    menuitem(2, "inverse rotation", inverse_rotation_mode)
end

function inverse_rotation_mode()
    swap_rotation_buttons = true
    menuitem(2, "normal rotation", standard_rotation_mode)
end