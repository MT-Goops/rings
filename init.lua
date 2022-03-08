rings = {}

-- MATERIALS
-- (only dependencies to moreores and glooptest)
rings.lumps ={
  Ag = "moreores:silver_lump",
  Au = "default:gold_lump",
  Mi = "moreores:mithril_lump"
}
rings.gems ={
  emerald = "glooptest:emerald_gem",
  ruby = "glooptest:ruby_gem",
  sapphire = "glooptest:sapphire_gem",
  topaz = "glooptest:topaz_gem",
  amethyst = "glooptest:amethyst_gem"
}
------

-- Load files

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath .. '/effects.lua')
dofile(modpath .. '/items.lua')
dofile(modpath .. '/activation.lua')
