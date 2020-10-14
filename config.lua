-- configuration options
function turn_on_shadow()
    display_shadow=true
    menuitem(1, "hide shadow", turn_off_shadow)
end

function turn_off_shadow()
    display_shadow=false
    menuitem(1, "show shadow", turn_on_shadow)
end