---------
-- API --
---------

table.insert(armor.elements, "ring")

--[[-- template declaration for rings
  armor:register_armor(ring_name, {
    description     = ring_description,
    inventory_image = ring_image,
    texture         = ring_texture,
    preview         = ring_preview,
    groups          = { armor_ring = ring_level , goops_fx = effect_id },
  })
]]

function rings.get_ring(user)
  local R = armor:get_weared_armor_elements(user).ring
  return {
    name        = R,
    description = minetest.registered_items[R].description,
    picture     = minetest.registered_items[R].inventory_image,
    level       = minetest.get_item_group(R, "armor_ring"),
    effect      = rings.effect(minetest.get_item_group(R, "goops_fx")),
  }
end

------------
-- CONFIG --
------------

local ring_models = {
  celestial = { 
    gem = rings.gems.amethyst, 
    effect = rings.effects.fly,
  },
  infernal = { 
    gem = rings.gems.ruby, 
    effect = rings.effects.fire_resistance,
  },
  abyssal = { 
    gem = rings.gems.sapphire, 
    effect = rings.effects.breath_hold,
  },
  enlightning = { 
    gem = rings.gems.topaz, 
    effect = rings.effects.shine,
  },
  hardening = { 
    gem = rings.gems.emerald,
    effect = rings.effects.iron_fist,
  },
}

local ring_quality = {
  { name = "Inferior ", metal = {rings.lumps.Ag,rings.lumps.Au} },
  { name = "", metal = {rings.lumps.Au} },
  { name = "Superior ", metal = {rings.lumps.Mi} },
  { name = "Supreme " }
}

------------
-- RECIPE --
------------

local function ring_recipe(mdl, lvl)
  -- ingredients
  local R = "goops_rings:"..mdl.."_ring"..tostring(lvl-1)
  local M = ring_quality[lvl].metal
  local G = ring_models[mdl] and ring_models[mdl].gem or "goops_rings:mismatched_gems"
  local D = "default:diamond"
  -- recipe
  local a,b,c,d
  a = (lvl<#ring_quality) and M[1] or R
  b = (lvl<#ring_quality) and M[#M] or R
  c = (lvl==1) and G or R
  d = (lvl<#ring_quality) and c or D
  return({{a,c,b},{c,d,c},{b,c,a}})
end

--------------------
-- REGISTER RINGS --
--------------------

local function register_ring(model,level,quality)
  local name = "goops_rings:"..model.."_ring"..level
  armor:register_armor(name, {
    description     = quality.name..model:gsub("^%l",string.upper).." Ring",
    inventory_image = "goops_"..model.."_ring"..level..".png",
    texture         = "goops_ring"..level..".png",
    preview         = "goops_ring"..level.."_preview.png",
    groups          = { armor_ring = level, goops_fx = ring_models[model].effect.id, ["goops_ring"..level] = 1},
    wield_scale     = {x=.25, y=.25, z=.25},
  })
  minetest.register_craft({
    output = name,
    recipe = ring_recipe(model,level)
  })
end

for m,_ in pairs(ring_models) do for i,q in ipairs(ring_quality) do
  register_ring(m,i,q)
end end

-----------------
-- RANDOM RING --
-----------------

minetest.register_craftitem("goops_rings:mismatched_gems",{
  description = "Mismatched gems",
  inventory_image = "goops_mismatched_gems.png"
})

minetest.register_craft({
  output = "goops_rings:mismatched_gems 5",
  type   = "shapeless",
  recipe = {"group:glooptest_gem","group:glooptest_gem","group:glooptest_gem","group:glooptest_gem","group:glooptest_gem"},
})

local function get_random_ring(itemstack, user, pointed_thing)
  local model_names = {}
  for n,_ in pairs(ring_models) do model_names[#model_names+1] = n end
  local model = model_names[math.random(#model_names)]
  local level = itemstack:get_name():sub(-1)
  minetest.item_drop(ItemStack("goops_rings:"..model.."_ring"..level), user, user:get_pos())
  itemstack:take_item()
  return itemstack
end

for i,q in ipairs(ring_quality) do
  local id = "random_ring"..i
  minetest.register_craftitem("goops_rings:"..id,{
    description     = q.name.."Random Ring",
    inventory_image = "goops_"..id..".png",
    on_use = get_random_ring
  })
  minetest.register_craft({
    output = "goops_rings:"..id.." 2",
    type   = "shapeless",
    recipe = {"group:goops_ring"..i,"group:goops_ring"..i,"group:goops_ring"..i}
  })
  minetest.register_craft({
    output = "goops_rings:"..id,
    recipe = ring_recipe("random",i)
  })
end
