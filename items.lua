-- CONFIG
local ring_models = {
  celestial = { 
    gem = rings.gems.amethyst, 
    effect = rings.effects.fly
  },
  infernal = { 
    gem = rings.gems.ruby, 
    effect = rings.effects.fire_resistance
  },
  abyssal = { 
    gem = rings.gems.sapphire, 
    effect = rings.effects.breath_hold
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
  { name = "Inferior ", metal = {rings.lumps.Ag,rings.lumps.Au}, duration = 15 },
  { name = "", metal = {rings.lumps.Au}, duration = 30 },
  { name = "Superior ", metal = {rings.lumps.Mi}, duration = 60 },
  { name = "Supreme ", duration = 120 }
}
------
------

local function ring_recipe(mdl, lvl)
  -- ingredients
  local R = "goops_rings:"..mdl.."_ring"..tostring(lvl-1)
  local M = ring_quality[lvl].metal
  local G = ring_models[mdl].gem
  local D = "default:diamond"
  -- recipe
  local a,b,c,d
  a = (lvl<#ring_quality) and M[1] or R
  b = (lvl<#ring_quality) and M[#M] or R
  c = (lvl==1) and G or R
  d = (lvl<#ring_quality) and c or D
  return({{a,c,b},{c,d,c},{b,c,a}})
end

local function register_ring(ringdef)
  local lvl = "ring"..tostring(ringdef.level)
  local id = ringdef.model.."_"..lvl
  armor:register_armor( "goops_rings:"..id,
  {
    description = ringdef.name,
    inventory_image = "goops_"..id..".png",
    texture = "goops_"..lvl..".png",
    preview = "goops_"..lvl.."_preview.png",
    groups = { armor_ring = 1 },
    wield_scale = {x=.25, y=.25, z=.25},
  })
  minetest.register_craft({
    output = "goops_rings:"..id,
    recipe = ring_recipe(ringdef.model,ringdef.level)
  })
end

table.insert(armor.elements, "ring")

for m,_ in pairs(ring_models) do for i,q in ipairs(ring_quality) do
  register_ring({
    model = m,
    level = i,
    name = q.name..m:gsub("^%l",string.upper).." Ring",
  })
end end

function rings.get_ring(user)
  local R = armor:get_weared_armor_elements(user).ring
  if R then
    local T = {
      model = R:match('%a*',13),
      level = tonumber(R:sub(-1)),
      description = ItemStack(R):get_description()
    }
    T.effect = ring_models[T.model].effect
    T.duration = tonumber(ring_quality[T.level].duration)
    T.picture = "goops_"..T.model.."_ring"..T.level..".png"
    return T
  end
end
