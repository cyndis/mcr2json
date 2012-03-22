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
      planks
    ).include?(block.name)
    return water(pos, block) if %w(water).include?(block.name)
    return sandstone(pos, block) if %w(sandstone).include?(block.name)

    return if %w(
      farmland seeds fence stairs unknown(102) wooden_pressure_plate slabs
      torch door cobblestone_stairs ladder wool unknown(106) leaves
    ).include?(block.name)

    $stderr.puts block.name
    return
    #raise 'Unsupported block type ' + block.name
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
    planks: [150,125,70].cn
  }
  # pos in [x,y,z]
  def self.block(pos, block)
    {
      'type' => 'box',
      'position' => pos,
      'extents' => [1,1,1],
      'color' => BLOCK_COLORS[block.name.to_sym],
      'blur' => 1.0
    }
  end

  def self.sandstone(pos, block)
    {
      'type' => 'box',
      'position' => pos,
      'extents' => [1,1,1],
      'color' => [0.8, 0.75, 0.2],
      'blur' => 0.75
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
      'position' => [0,extents._y+13,0],
      'extents' => [extents._x, 0.2, extents._z],
      'color' => [1,1,1],
      'emit' => 1.0,
      'blur' => 0.0
    }
  end
end
