-- FLY

local function fly_check(user)
  return not minetest.get_player_privs(user:get_player_name()).fly
end

local function fly_activate(user)
  local playername = user:get_player_name()
  local privs = minetest.get_player_privs(playername)
  privs.fly = true
  minetest.set_player_privs(playername, privs)
end

local function fly_deactivate(user)
  local playername = user:get_player_name()
  local privs = minetest.get_player_privs(playername)
  privs.fly = nil
  minetest.set_player_privs(playername, privs)
end

-- SHINE

local function shine_activate(user)
  p = rings.profile(user)
  p.fx.path = {}
end

local function shine_deactivate(user)
  p = rings.profile(user)
  for n,t in pairs(p.fx.path) do
    minetest.remove_node(n)
  end
  p.fx.path = nil
end

-- IRON FIST
local function iron_fist_apply(itemstack, user, pointed_thing)
  if pointed_thing.type=="node" then
    minetest.dig_node(pointed_thing.under)
    minetest.sound_play("goops_rings_gong",{to_player = user:get_player_name(),gain =.5})
    minetest.chat_send_player(user:get_player_name(), "Feel the Power of the Iron Fist")
  end
end

-- DEFS

rings.effects = {
  fly             = {
    name          = "Flight Privilege",
    check         = fly_check,
    on_activate   = fly_activate,
    on_deactivate = fly_deactivate,
  },
  breath_hold     = {
    name          = "Breath Hold",
  },
  fire_resistance = {
    name          = "Fire Resistance",
  },
  shine           = {
    name          = "Shining",
    on_activate   = shine_activate,
    on_deactivate = shine_deactivate,
  },
  iron_fist       = {
    name          = "Iron Fist",
    apply         = iron_fist_apply,
  },
}

-- FIRE AND WATER RESISTANCES

minetest.register_on_player_hpchange(function(user, hp_change, reason)
  local p = rings.profile(user)
  if reason.type == "drown" then
    if p.fx and p.fx.name == rings.effects.breath_hold.name then hp_change = 0 end
  end
  if reason.type == "node_damage" then
    for _,igniter in pairs(armor.fire_nodes) do if reason.node == igniter[1] then
      if p.fx and p.fx.name == rings.effects.fire_resistance.name then hp_change = 0 end
    end end
  end
  return hp_change
end, true)

-- SHINE

local glownode = "goops_rings:air_glowing"
local glowtime = .6

minetest.register_node(glownode, {
  description         = "Glowing Air",
  drawtype            = "airlike",
  paramtype           = "light",
  sunlight_propagates = true,
  light_source        = 14,
  walkable            = false,
  pointable           = false,
  diggable            = false,
  buildable_to        = true,
  air_equivalent      = true,
  drop                = "",
  groups              = {
    not_in_creative_inventory = 1
  },
})

minetest.register_lbm({
	name = "goops_rings:remove_light",
	nodenames = {glownode},
	run_at_every_load = true, 
	action = minetest.remove_node,
})

minetest.register_globalstep(function(dtime)
  for u,p in pairs(rings.users) do
    if p.fx and p.fx.name == rings.effects.shine.name then 
      local path = p.fx.path
      if path then
        for n,_ in pairs(path) do
          path[n] = path[n] + dtime
        end
      end
      local pos = vector.add(vector.round(minetest.get_player_by_name(u):get_pos()),{x=0,y=1,z=0})
      if minetest.get_node(pos).name=="air" then 
        minetest.set_node(pos,{name = glownode}) 
        path[pos] = 0
      end
      for n,t in pairs(path) do if n~= pos and t > glowtime then
        minetest.remove_node(n)
      end
    end
  end
end
end)
