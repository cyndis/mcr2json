class Mcr2Json
end

class Array
  def cn
    map { |c| c / 255.0 }
  end
end

module Mcr2Json::Primitives
  def self.make(pos, block)
    return if %w(air dead_shrubs).include?(block.name)
    return block(pos, block) if %w(
      dirt grass sand stone coal gravel ironore cactus log cobblestone
      planks sandstone ice leaves
    ).include?(block.name)
    return snow(pos, block) if %w(snow).include?(block.name)
    return water(pos, block) if %w(water watersource).include?(block.name)
    return sandstone(pos, block) if %w(sandstone).include?(block.name)

    $stderr.puts 'Unsupported block type: ' + block.name
    nil
  end

  BLOCK_COLORS = {
    dirt: [85,60,40].cn,
    grass: [0, 1, 0],
    sand: [0.8, 0.75, 0.0],
    cobblestone: [70,70,70].cn,
    stone: [0.7, 0.7, 0.7],
    ironore: [0.75, 0.75, 0.75],
    coal: [0.3, 0.3, 0.3],
    gravel: [120,120,120].cn,
    cactus: [0, 0.75, 0],
    log: [64,50,30].cn,
    planks: [150,125,70].cn,
    ice: [165, 194, 245].cn,
    leaves: [0.1, 0.75, 0.1],

    # unverified
    sandstone: [0.8, 0.75, 0.2],
    snow: [0.9, 0.9, 0.9]
  }

  BLOCK_BLUR = {
    snow: 0.9,
    ice: 0.5
  }
  
  # pos in [x,y,z]
  def self.block(pos, block)
    {
      'type' => 'box',
      'position' => pos,
      'extents' => [1,1,1],
      'color' => BLOCK_COLORS[block.name.to_sym],
      'blur' => BLOCK_BLUR[block.name.to_sym] || 1.0
    }
  end

  def self.snow(pos, block)
    height = (block.data % 7 + 1) / 8.0

    {
      'type' => 'box',
      'position' => [pos.x, pos.y - 0.5 + height / 2.0, pos.z],
      'extents' => [1, height, 1],
      'color' => BLOCK_COLORS[:snow],
      'blur' => BLOCK_BLUR[:snow]
    }
  end

  def self.water(pos, block)
    {
      'type' => 'box',
      'position' => pos,
      'extents' => [1, 0.7, 1],
      'color' => [0,0,1],
      'blur' => 0.6
    }
  end

  def self.make_sun(extents)
    {
      'type' => 'box',
      'position' => [0,extents.y+20,0],
      'extents' => [extents.x, 0.2, extents.z],
      'color' => [1,1,1],
      'emit' => 0.75,
      'blur' => 1.0
    }
  end
end
