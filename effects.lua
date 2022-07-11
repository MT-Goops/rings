---------
-- API --
---------

rings.effects = {}

--[[-- definition template
effect          = {
  id            = effect_id            -- unique identifier
  name          = effect_name,
  init          = effect_init,         -- f(). If set, called at registration
  check         = effect_check,        -- f(user). If set, returns a string when effect can't be applied
  on_activate   = effect_on_activate,  -- f(user). If set, called at activation
  iter          = effect_iter,         -- number. If set, effect_on_activate is called every iter seconds
  apply         = effect_apply,        -- f(itemstack, user, pointed_thing). If set, called via activation ring when effect is active
  on_deactivate = effect_on_deactivate,   -- f(user). If set, called at deactivation
  data          = {}                   -- User dependant data
  globalstep    = effect_globalstep,   -- f(dtime). If set, called every server step
},
]]

function rings.effect(i)
  for n, fx in pairs(rings.effects) do
    if fx.id == i then return fx end
  end
end

function rings.register_effect(n, def)
  if def.init then def.init() end
  rings.effects[n] =
  {
    name          = def.name,
    check         = def.check,
    on_activate   = def.on_activate,
    iter          = def.iter,
    apply         = def.apply,
    on_deactivate = def.on_deactivate,
    data          = def.data
  }
  if def.globalstep then minetest.register_globalstep(def.globalstep) end
end

-----------------
-- # EFFECTS # --
-----------------

---------
-- FLY --
---------

local function fly_check(user)
  if minetest.get_player_privs(user:get_player_name()).fly then
    return "Fly privilege is already permanently granted"
  end
end

local function fly_on_activate(user)
  local playername = user:get_player_name()
  local privs = minetest.get_player_privs(playername)
  privs.fly = true
  minetest.set_player_privs(playername, privs)
end

local function fly_on_deactivate(user)
  local playername = user:get_player_name()
  local privs = minetest.get_player_privs(playername)
  privs.fly = nil
  minetest.set_player_privs(playername, privs)
end

---------------
-- IRON FIST --
---------------

local function iron_fist_apply(itemstack, user, pointed_thing)
  if pointed_thing.type=="node" then
    minetest.dig_node(pointed_thing.under)
    minetest.sound_play("goops_rings_gong",{to_player = user:get_player_name(),gain =.5})
  end
end

----------------------
-- WATER RESISTANCE --
----------------------

local function breath_hold_init()
  minetest.register_on_player_hpchange(function(user, hp_change, reason)
    local R = rings.get_ring(user)
    if reason.type == "drown" and R and R.effect.name == rings.effects.breath_hold.name then
      rings.auto_activate(user)
    end
    local p = rings.profile(user)
    if reason.type == "drown" and p.fx and p.fx.name == rings.effects.breath_hold.name then
      hp_change = 0
    end
    return hp_change
  end, true)
end

---------------------
-- FIRE RESISTANCE --
---------------------

local function is_fire(reason)
  if reason.type == "node_damage" then
    for _,igniter in pairs(armor.fire_nodes) do
      if (reason.node == igniter[1]) then return true end
    end
  end
end

local function fire_resistance_init()
  minetest.register_on_player_hpchange(function(user, hp_change, reason)
    local R = rings.get_ring(user)
    if is_fire(reason) and R and R.effect.name == rings.effects.fire_resistance.name then
      rings.auto_activate(user)
    end
    local p = rings.profile(user)
    if is_fire(reason) and p.fx and p.fx.name == rings.effects.fire_resistance.name then
      hp_change = 0
    end
    return hp_change
  end, true)
end

-----------
-- SHINE --
-----------

-- config
local glowtime = .6
local glownodes = { "air", "default:water_source", "default:water_flowing", "default:river_water_source", "default:river_water_flowing" }

-- glownodes
 
local revert = {}

local function register_glownode(n)
  local g = "goops_rings:"..n:gsub('.*:','').."_glowing"
  revert[g] = n
  local def = table.copy(minetest.registered_nodes[n])
  def.description = "Glowing "..def.description
  def.light_source = 14
  def.groups.not_in_creative_inventory = 1
  def.liquidtype = nil
  minetest.register_node(g, def)
  minetest.register_lbm({
    name              = "goops_rings:remove_"..g:gsub('.*:',''),
    nodenames         = {g},
    run_at_every_load = true,
    action            = function(pos,node) minetest.swap_node(pos,{name = n}) end,
  })
end

for _,n in pairs(glownodes) do
  register_glownode(n)
end

local function restore_node(pos)
  local g = minetest.get_node(pos).name
  if revert[g] then
    minetest.swap_node(pos, {name = revert[g]})
  end
end

-- defs

local function shine_globalstep(dtime)
  for u,p in pairs(rings.users) do
    if p.fx and p.fx.name == rings.effects.shine.name then
      local path = p.fx.data.path
      if path then
        for n,_ in pairs(path) do
          path[n] = path[n] + dtime
        end
      end
      local pos = vector.add(vector.round(minetest.get_player_by_name(u):get_pos()),{x=0,y=1,z=0})

      for _,n in pairs(glownodes) do
        if minetest.get_node(pos).name == n then
          minetest.set_node(pos, {name = "goops_rings:"..n:gsub('.*:','').."_glowing"})
          path[pos] = 0
        end
      end

      for n,t in pairs(path) do
        if n~= pos and t > glowtime then
          restore_node(n)
          path[n] = nil
        end
      end

    end
  end
end

local function shine_on_deactivate(user)
  local p = rings.profile(user)
  for n,t in pairs(p.fx.data.path) do
    restore_node(n)
  end
  p.fx.data.path = {}
end

----------------------
-- REGISTER EFFECTS --
----------------------

local defs = {
  fly             = {
    name          = "Flight Privilege",
    check         = fly_check,
    on_activate   = fly_on_activate,
    on_deactivate = fly_on_deactivate,
  },
  breath_hold     = {
    name          = "Breath Hold",
    init          = breath_hold_init
  },
  fire_resistance = {
    name          = "Fire Resistance",
    init          = fire_resistance_init
  },
  shine           = {
    name          = "Shining",
    on_deactivate = shine_on_deactivate,
    data          = { path={} },
    globalstep    = shine_globalstep,
  },
  iron_fist       = {
    name          = "Iron Fist",
    apply         = iron_fist_apply,
  },
}

local function length(T)
  local l = 0
  for a,b in pairs(T) do l = l + 1 end
  return l
end

for n, def in pairs(defs) do
  rings.register_effect(n, def)
  rings.effects[n].id = length(rings.effects)
end
