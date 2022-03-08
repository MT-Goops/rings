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
local def = table.copy(minetest.registered_nodes["air"])
def.paramtype = "light"
def.light_source = 14
def.on_construct = function(pos) minetest.after(.1, minetest.remove_node,pos) end
minetest.register_node(glownode,def)

minetest.register_globalstep(function(dtime)
  for u,p in pairs(rings.users) do
    if p.fx and p.fx.name == rings.effects.shine.name then 
      local pos = vector.add(vector.round(minetest.get_player_by_name(u):get_pos()),{x=0,y=1,z=0})
      if minetest.get_node(pos).name=="air" then minetest.set_node(pos,{name=glownode}) end
    end
  end
end)
