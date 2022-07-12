if minetest.get_modpath("glooptest") then
  local gems = {"ruby", "sapphire", "emerald", "topaz", "amethyst"}

  for _,n in pairs(gems) do
    -- compatibility with backup items
    minetest.register_alias_force("goops_rings:mineral_"..n, "glooptest:mineral_"..n)
    minetest.register_alias_force("goops_rings:"..n.."_gem", "glooptest:"..n.."_gem")
  end

else 
  -- Backup items : copied from glooptest mod

  local function register_ore(name, uses)
    minetest.register_node("goops_rings:mineral_"..name, {
      description = name:gsub("^%l",string.upper).." Ore",
      tiles = {"default_stone.png^glooptest_mineral_"..name..".png"},
      is_ground_content = true,
      drop = "goops_rings:"..name.."_gem",
      groups = {cracky=1},
      sounds = default.node_sound_stone_defaults()
    })
    minetest.register_ore({
      ore_type       = "scatter",
      ore            = "goops_rings:mineral_"..name,
      wherein        = uses.generate_inside_of,
      clust_scarcity = uses.chunks_per_mapblock,
      clust_num_ores = uses.max_blocks_per_chunk,
      clust_size     = uses.chunk_size,
      y_min     = uses.miny,
      y_max     = uses.maxy,
    })
    minetest.register_craftitem("goops_rings:"..name.."_gem", {
      description = name:gsub("^%l",string.upper),
      inventory_image = "glooptest_gem_"..name..".png",
      groups = {glooptest_gem=1},
    })
  end

  register_ore("ruby", {
    generate_inside_of = "default:stone",
    chunks_per_mapblock = 15*15*15,
    chunk_size = 5,
    max_blocks_per_chunk = 5,
    miny = -3000,
    maxy = -30
  })

  register_ore("sapphire", {
    generate_inside_of = "default:stone",
    chunks_per_mapblock = 15*15*15,
    chunk_size = 5,
    max_blocks_per_chunk = 5,
    miny = -3000,
    maxy = -30
  })

  register_ore("emerald", {
    generate_inside_of = "default:stone",
    chunks_per_mapblock = 15*15*15,
    chunk_size = 4,
    max_blocks_per_chunk = 4,
    miny = -5000,
    maxy = -70
  })

  register_ore("topaz", {
    generate_inside_of = "default:stone",
    chunks_per_mapblock = 15*15*15,
    chunk_size = 4,
    max_blocks_per_chunk = 4,
    miny = -5000,
    maxy = -70
  })

  register_ore("amethyst", {
    generate_inside_of = "default:stone",
    chunks_per_mapblock = 15*15*15,
    chunk_size = 3,
    max_blocks_per_chunk = 3,
    miny = -31000,
    maxy = -128
  })

end
