---------
-- API --
---------

rings.users = {}

function rings.profile(user)
  local playername = user:get_player_name()
  if not rings.users[playername] then rings.users[playername] = {} end
  return rings.users[playername]
end

--[[-- profile structure
{
status        = nil/"usage/"cooldown",
fx = {
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
]]

-----------------
-- USER UPDATE --
-----------------

local cooldown = tonumber(minetest.settings:get("rings_cooldown")) or 15


local function duration(level)
  local dur = tonumber(minetest.settings:get("rings_dur")) or 15
  return dur * 2^(level-1)
end

local function fx_update(user)
  local p = rings.profile(user)
  if p.status == nil then
    p.fx            = nil
  elseif p.status == "usage" then
    local R = rings.get_ring(user)
    p.fx            = R.effect
    p.fx.picture    = R.picture
    p.fx.time_left  = duration(R.level)
  elseif p.status == "cooldown" then
    p.fx            = { name = "Cooldown" }
    p.fx.picture    = "goops_activation_ring.png"
    p.fx.time_left  = cooldown
  end
end

local function hud_update(user)
  local p = rings.profile(user)
  if p.fx then
    if not p.hud then
      p.hud={
        pic = user:hud_add({
          hud_elem_type = "image",
          position      = {x = 0, y = 1},
          offset        = {x = 44, y = -44},
          alignment     = {x = 0, y = 0},
          scale         = {x = 1, y = 1},
        }),
        txt = user:hud_add({
          hud_elem_type = "text",
          style         = 1,
          position      = {x = 0, y = 1},
          offset        = {x = 44, y = -44},
          alignment     = {x = 0, y = 0},
          scale         = {x = 100, y = 100},
          number        = 0xFFFFFF,
        })
      }
    end
    user:hud_change(p.hud.pic, "text", p.fx.picture)
    user:hud_change(p.hud.txt, "text", p.fx.time_left)
  else
    if p.hud then
      user:hud_remove(p.hud.pic)
      user:hud_remove(p.hud.txt)
      p.hud = nil
    end
  end
end

local function user_update(user, status)
  local p = rings.profile(user)
  p.status = status
  fx_update(user)
  hud_update(user)
  minetest.sound_play("goops_rings_spin", {to_player = user:get_player_name(),gain =.5})
end

-------------------------
-- ACTIVATE/DEACTIVATE --
-------------------------

local function notify(user, str)
  minetest.chat_send_player(user:get_player_name(), str)
end

local function activate(itemstack, user, pointed_thing)
  local R = rings.get_ring(user)
  if not R then
    notify(user, "Your not wearing a ring !\nTry and equip one...")
  else
    local p = rings.profile(user)
    if p.status == "cooldown" then
      notify(user, "Your ring is cooling down")
    elseif p.status == "usage" then
      if p.fx.apply then
        p.fx.apply(itemstack, user, pointed_thing)
      else
        notify(user,"You are already using a ring !\nRight click to deactivate it...")
      end
    else
      local fx = R.effect
      if (fx.check and fx.check(user)) then
        notify(user, fx.check(user))
      else
        user_update(user, "usage")
        if fx.on_activate then fx.on_activate(user) end
        notify(user, "Activation of "..R.description.."\n"..fx.name.." granted for "..duration(R.level).." seconds")
      end
    end
  end
end

local function deactivate(user)
  local p = rings.profile(user)
  if p.status == "usage" then
    if p.fx.on_deactivate then p.fx.on_deactivate(user) end
    notify(user, p.fx.name.." revoked.\nEntering cooldown for "..cooldown.." seconds")
    user_update(user, "cooldown")
  elseif p.status == "cooldown" then
    notify(user, "Your ring is ready !")
    user_update(user, nil)
  end
end

local function stop(itemstack, user, pointed_thing)
  if rings.profile(user).status == "usage" then
    deactivate(user)
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
    if p.fx and p.fx.on_deactivate then p.fx.on_deactivate(user) end
    user_update(user,nil)
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

minetest.register_craftitem("goops_rings:activation_ring", {
  description = "Activation Ring",
  inventory_image = "goops_activation_ring.png",
  wield_scale = {x=.25, y=.25, z=.25},
  stack_max = 1,
  on_use = activate,
  on_place = stop,
  on_secondary_use = stop
})

minetest.register_craft({
  output = "goops_rings:activation_ring",
  recipe = {
    {rings.lumps.Au,rings.gems.emerald,rings.lumps.Au},
    {rings.gems.sapphire,rings.gems.ruby,rings.gems.amethyst},
    {rings.lumps.Au,rings.gems.topaz,rings.lumps.Au}
  }
})
