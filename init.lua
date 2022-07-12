rings = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())

---------------
-- MATERIALS -- (NB: only dependencies to moreores and glooptest)
---------------

dofile(modpath .. '/glooptest.lua')

rings.lumps ={
  Ag = "moreores:silver_lump",
  Au = "default:gold_lump",
  Mi = "moreores:mithril_lump"
}

rings.gems ={
  emerald = "goops_rings:emerald_gem",
  ruby = "goops_rings:ruby_gem",
  sapphire = "goops_rings:sapphire_gem",
  topaz = "goops_rings:topaz_gem",
  amethyst = "goops_rings:amethyst_gem"
}

----------------
-- LOAD FILES --
----------------

dofile(modpath .. '/effects.lua')

dofile(modpath .. '/items.lua')

dofile(modpath .. '/activation.lua')
