# vim: ts=2 sw=2

require 'rubycraft'
require 'json'
require_relative 'primitives'

class Array
  def x
    self[1]
  end
  def y
    self[2]
  end
  def z
    self[0]
  end

  def _x
    self[0]
  end
  def _y
    self[1]
  end
  def _z
    self[2]
  end
end

class Mcr2Json
  LOAD_REGION = '/home/cyndis/.spoutcraft/saves/Derp/region/r.0.0.mcr'

  def initialize(from)
    @region = RubyCraft::Region.fromFile(from)
  end

  # origin and extents in [x, y, z]
  def convert(origin, extents)
    cube = @region.cube(origin._z, origin._x, origin._y,
                        :width => extents._z, :length => extents._x,
                        :height => extents._y)

    json = {'scene' => []}

    cube.each do |block, z, x, y|
      found_trans = false
      (z-1..z+1).each do |zp|
        next if zp < 0
        (x-1..x+1).each do |xp|
          next if xp < 0
          (y-1..y+1).each do |yp|
            b = @region.chunk(zp / 16, xp / 16)[zp % 16, xp % 16, 55+yp]
            if (b.name == 'air')
              found_trans = true
              break
            end
          end
          break if found_trans
        end
        break if found_trans
      end
      next if not found_trans

      scene_pos = [x - origin._x - extents._x / 2.0,
                   y,
                   z - origin._z - extents._z / 2.0]

      obj = Primitives.make(scene_pos, block)
      json['scene'] << obj if obj
    end

    json['scene'] << Primitives.make_sun(extents)

    json['camera'] = {
      'position' => [extents._x / 2.0, extents._y / 2.0 + 7, extents._z / 2.0],
      'look_at' => [0, 0, 0],
      'fov' => 90,
      'aspect' => 480/320.0
    }

    return JSON.pretty_generate(json)
  end
end

if (__FILE__ == $0)
  mj = Mcr2Json.new(Mcr2Json::LOAD_REGION)

  puts mj.convert([0,55,0], [100, 30, 100])
end
