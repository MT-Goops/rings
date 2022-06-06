---------
-- API --
---------

rings.users = {}

function rings.profile(user)
  local playername = user:get_player_name()
  if not rings.users[playername] then rings.users[playername] = { flags = { status = 0, auto = 0, hud = 0 } } end
  return rings.users[playername]
end

--[[-- profile structure
{
  flags = {
    status        = int,                 -- 0: idle, 1: active, 2: cooldown
    auto          = int,                 -- 0: manual activation, 1: automatic activation
    hud           = int,                 -- 0: default, 1: hidden, 2: locked on
  },
  fx    = {
    name          = effect_name,
    picture       = effect_picture,      -- Displayed in HUD
    check         = effect_check,        -- f(user). If set, returns a string when effect can't be applied
    on_activate   = effect_on_activate,  -- f(user). If set, called at activation
    iter          = effect_iter,         -- number. If set, effect_on_activate is called every iter seconds
    apply         = effect_apply,        -- f(itemstack, user, pointed_thing). If set, called via activation ring when effect is active
    on_deactivate = effect_deactivate,   -- f(user). If set, called at deactivation
    data          = {}                   -- User dependant data
    time_left     = time_left,
  },
  hud   = {
    pic = pic_index,
    txt = txt_index
  },
}
]]

function rings.auto_activate(user)
  local p = rings.profile(user)
  if p.flags.status == 0 and p.flags.auto == 1 then
    local ring = "goops_rings:activation_ring"
    if user:get_inventory():contains_item("main", ring) then
      minetest.registered_items[ring].on_use(ItemStack(""),user)
    end
  end
end

-------------------
-- LOAD SETTINGS --
-------------------

local cooldown = tonumber(minetest.settings:get("rings_cooldown")) or 15

local function duration(level)
  local dur = tonumber(minetest.settings:get("rings_dur")) or 15
  return dur * 2^(level-1)
end

-----------------
-- USER UPDATE --
-----------------

local function fx_update(user)
  local p = rings.profile(user)
  if p.flags.status == 0 then 
    -- idle
    p.fx            = nil
  elseif p.flags.status == 1 then 
    -- active
    local R = rings.get_ring(user)
    p.fx            = R.effect
    p.fx.picture    = R.picture
    p.fx.time_left  = duration(R.level)
  elseif p.flags.status == 2 then 
    -- cooldown
    p.fx            = { name = "Cooldown" }
    p.fx.picture    = "goops_activation_ring.png"
    p.fx.time_left  = cooldown
  end
end

local function hud_update(user)
  local p = rings.profile(user)
  if p.flags.hud ~= 1 and (p.fx or p.flags.hud == 2 or p.flags.auto == 1) then
    if not p.hud then
      p.hud={
        pic = user:hud_add({
          hud_elem_type = "image",
          position      = {x = 1, y = 1},
          offset        = {x = -66, y = -44},
          alignment     = {x = 0, y = 0},
          scale         = {x = 1, y = 1},
        }),
        txt = user:hud_add({
          hud_elem_type = "text",
          style         = 1,
          position      = {x = 1, y = 1},
          offset        = {x = -66, y = -44},
          alignment     = {x = 0, y = 0},
          scale         = {x = 100, y = 100},
          number        = 0xFFFFFF,
        })
      }
    end
    if p.fx then
      user:hud_change(p.hud.pic, "text", p.fx.picture)
      user:hud_change(p.hud.txt, "text", p.fx.time_left)
    else
      local R = rings.get_ring(user)
      if p.flags.auto == 1 then
        if user:get_inventory():contains_item("main", "goops_rings:activation_ring") then
          user:hud_change(p.hud.pic, "text", R and R.picture or "blank.png")
          user:hud_change(p.hud.txt, "text", R and "auto" or "")
        end
      else
        user:hud_change(p.hud.pic, "text", R and R.picture or "blank.png")
        user:hud_change(p.hud.txt, "text", R and "0" or "")
      end
    end
  else
    if p.hud then
      user:hud_remove(p.hud.pic)
      user:hud_remove(p.hud.txt)
      p.hud = nil
    end
  end
end

local function user_update(user)
  local p = rings.profile(user)
  p.flags.status = (p.flags.status + 1) % 3
  fx_update(user)
  hud_update(user)
  minetest.sound_play("goops_rings_spin", {to_player = user:get_player_name(),gain =.5})
end

---------------------
-- AUTO-ACTIVATION --
---------------------

minetest.register_globalstep(function(dtime)
  for _,u in pairs(minetest.get_connected_players()) do
    if rings.profile(u).flags.auto == 1 then
      local R = rings.get_ring(u)
      if R and R.effect.name == rings.effects.shine.name then
        local pos = vector.add(vector.round(u:get_pos()),{x=0,y=1,z=0})
        local light = minetest.get_node_light(pos)
        if light and light < 8 then
          rings.auto_activate(u)
        end
      end
    end
  end
end)

local function falling(user)
  local falling = true
  local fall = 0
  repeat
    fall = fall + 1
    local pos = vector.add(vector.round(user:get_pos()),{x=0,y=-fall,z=0})
    local node = minetest.registered_nodes[minetest.get_node(pos).name]
    falling = node and not node.walkable or false
  until not falling or fall == 4
  return falling
end

minetest.register_globalstep(function(dtime)
  for _,u in pairs(minetest.get_connected_players()) do
    if rings.profile(u).flags.auto == 1 then
      local R = rings.get_ring(u)
      if R and R.effect.name == rings.effects.fly.name then
        if falling(u) and not u:get_player_control().sneak then
          rings.auto_activate(u)
        end
      end
    end
  end
end)

-------------------------
-- ACTIVATE/DEACTIVATE --
-------------------------
local verbose = minetest.settings:get("rings_verbose") or false

local function notify(user, str)
  if verbose then minetest.chat_send_player(user:get_player_name(), str) end
end

local function activate(itemstack, user, pointed_thing)
  local R = rings.get_ring(user, true)
  if R then
    local p = rings.profile(user)
    if p.flags.status == 0 then 
      -- idle
      local fx = R.effect
      if (fx.check and fx.check(user)) then
        notify(user, fx.check(user))
      else
        user_update(user)
        if fx.on_activate then fx.on_activate(user) end
        notify(user, "Activation of "..R.description.."\n"..fx.name.." granted for "..duration(R.level).." seconds")
      end
    elseif p.flags.status == 1 then 
      -- already active
      if p.fx.apply then
        p.fx.apply(itemstack, user, pointed_thing)
      else
        notify(user,"You are already using a ring !\nRight click to deactivate it...")
      end
    elseif p.flags.status == 2 then 
      -- cooldown
      notify(user, "Your ring is cooling down")
    end
  end
end

local function deactivate(user)
  local p = rings.profile(user)
  if p.flags.status == 1 then 
    -- deactivate
    if p.fx.on_deactivate then p.fx.on_deactivate(user) end
    notify(user, p.fx.name.." revoked.\nEntering cooldown for "..cooldown.." seconds")
    user_update(user) -- enter cooldown
  elseif p.flags.status == 2 then 
    -- cooldown is over
    notify(user, "Your ring is ready !")
    user_update(user) -- exit cooldown
  end
end

-------------
-- REFRESH --
-------------

local timer = 0

minetest.register_globalstep(function(dtime)
  timer = timer + dtime
  if timer < 1 then return end
  timer = 0
  for u,p in pairs(rings.users) do
    local usr = minetest.get_player_by_name(u)
    if not usr then
      rings.users[u] = nil
    else
      local fx = p.fx
      if fx then
        fx.time_left = fx.time_left-1
        if fx.time_left > 0 then
          if fx.iter then fx.on_activate(usr) end
        else
          deactivate(usr)
        end
      end
      hud_update(usr)
    end
  end
end)

-------------
-- CLEANUP --
-------------

local function remove(user)
  if user then
    local p = rings.profile(user)
    if p.fx and p.fx.on_deactivate then
      p.fx.on_deactivate(user) 
    end
    if p.hud then
      user:hud_remove(p.hud.pic)
      user:hud_remove(p.hud.txt)
      p.hud = nil
    end
    rings.users[user:get_player_name()] = nil
  end
end

minetest.register_on_dieplayer(remove)

minetest.register_on_leaveplayer(remove)

minetest.register_on_shutdown(function()
  for u,_ in pairs(rings.users) do remove(minetest.get_player_by_name(u)) end
end)

---------------------
-- ACTIVATION RING --
---------------------

local function lmb(itemstack, user, pointed_thing)
  if user:get_player_control().sneak then 
    local p = rings.profile(user)
    p.flags.auto = (p.flags.auto + 1) % 2
  else 
    activate(itemstack, user, pointed_thing)
  end
end

local function rmb(itemstack, user, pointed_thing)
  if user:get_player_control().sneak then
    local p = rings.profile(user)
    p.flags.hud = (p.flags.hud + 1) % 3
  else 
    if rings.profile(user).flags.status == 1 then -- only if active
      deactivate(user)
    end
  end
end

minetest.register_craftitem("goops_rings:activation_ring", {
  description = "Activation Ring",
  inventory_image = "goops_activation_ring.png",
  wield_scale = {x=.25, y=.25, z=.25},
  stack_max = 1,
  on_use = lmb,
  on_place = rmb,
  on_secondary_use = rmb,
})

minetest.register_craft({
  output = "goops_rings:activation_ring",
  recipe = {
    {rings.lumps.Au,rings.gems.emerald,rings.lumps.Au},
    {rings.gems.sapphire,rings.gems.ruby,rings.gems.amethyst},
    {rings.lumps.Au,rings.gems.topaz,rings.lumps.Au}
  }
})
