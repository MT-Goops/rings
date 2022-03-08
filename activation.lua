local cooldown = tonumber(minetest.settings:get("rings_cooldown")) or 15

-- PROFILES
-- TODO shift + click : hud_toggle

rings.users = {}

function rings.profile(user)
  -- also used in effects.lua
  local playername = user:get_player_name()
  if not rings.users[playername] then rings.users[playername] = {} end
  return rings.users[playername]
end

local function fx_update(user)
  local p = rings.profile(user)
  if p.status == nil then
    p.fx            = nil
  elseif p.status == "usage" then
    local R = rings.get_ring(user)
    p.fx            = R.effect
    p.fx.texture    = R.picture
    p.fx.time_left  = R.duration
  elseif p.status == "cooldown" then
    p.fx            = { name = "Cooldown" }
    p.fx.texture    = "goops_activation_ring.png"
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
    user:hud_change(p.hud.pic, "text", p.fx.texture)
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
  minetest.sound_play("goops_rings_spin",{to_player = user:get_player_name(),gain =.5})
end

------
------


-- ACTIVATE/DEACTIVATE
-- TODO shift + right click : auto-activation

local function notify(user, str)
  minetest.chat_send_player(user:get_player_name(), str)
end

local function rings_activate(itemstack, user, pointed_thing)
  local R = rings.get_ring(user)
  if not R then
    notify(user,"Your not wearing a ring !\nTry and equip one...")
  else
    local p = rings.profile(user)
    if p.status == "cooldown" then
      notify(user,"Your ring is cooling down")
    elseif p.status == "usage" then
      if p.fx.apply then
        p.fx.apply(itemstack, user, pointed_thing)
      else
        notify(user,"You are already using a ring !\nRight click to deactivate it...")
      end
    else
      fx = R.effect
      if (fx.check and not fx.check(user)) then
        notify(user, fx.name.." is already permanently granted")
      else
        user_update(user, "usage")
        if fx.on_activate then fx.on_activate(user) end
        notify(user, "Activation of "..R.description.."\n"..fx.name.." granted for "..R.duration.." seconds")
      end
    end
  end
end

local function rings_deactivate(user)
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

local function rings_stop(itemstack, user, pointed_thing)
  local p = rings.profile(user)
  if p.status == "cooldown" then
    notify(user, "Your ring is cooling down")
  else
    rings_deactivate(user)
  end
end

------
------

-- REFRESH

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
          rings_deactivate(usr)
        end
      end
      hud_update(usr)
    end
  end
end)

------
------

-- REMOVE

local function remove(user)
  local p = rings.profile(user)
  if p.fx and p.fx.on_deactivate then p.fx.on_deactivate(user) end
  user_update(user,nil)
end

minetest.register_on_dieplayer(function(user)
  remove(user)
end)

minetest.register_on_leaveplayer(function(user)
  remove(user)
end)

minetest.register_on_shutdown(function()
  for u,_ in pairs(rings.users) do
    remove(minetest.get_player_by_name(u))
  end
end)

------
------

-- Activation ring

minetest.register_craftitem("goops_rings:activation_ring", {
  description = "Activation Ring",
  inventory_image = "goops_activation_ring.png",
  wield_scale = {x=.25, y=.25, z=.25},
  stack_max = 1,
  on_use = rings_activate,
  on_secondary_use = rings_stop
})

minetest.register_craft({
  output = "goops_rings:activation_ring",
  recipe = {
    {rings.lumps.Au,rings.gems.emerald,rings.lumps.Au},
    {rings.gems.sapphire,rings.gems.ruby,rings.gems.amethyst},
    {rings.lumps.Au,rings.gems.topaz,rings.lumps.Au}
  }
})
