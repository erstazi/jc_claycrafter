local modpath = core.get_modpath(core.get_current_modname())
local S = core.get_translator(core.get_current_modname())

-- TODO: Investigate function to automatically get mod name.

dofile(modpath .. "/items.lua")
dofile(modpath .. "/claycrafter.lua")
