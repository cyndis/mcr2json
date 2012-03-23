# vim: ts=2 sw=2

begin
  require 'rubycraft'
rescue LoadError
  $stderr.puts 'You need to install the rubycraft gem.'
  $stderr.puts '$ sudo gem install rubycraft'
  exit
end
require 'json'
require_relative 'primitives'

class Array
  def x
    self[0]
  end
  def y
    self[1]
  end
  def z
    self[2]
  end
end

class Mcr2Json
end

class Mcr2Json::World
  def initialize(path)
    @path = path

    @region_cache = {}
    @chunk_cache = {}
  end

  CHUNK_SIZE = 16
  REGION_SIZE = CHUNK_SIZE * 32
  class Coordinate < Struct.new(:region, :chunk, :block)
    def inspect
      "(R#{region.inspect} C#{chunk.inspect} B#{block.inspect})"
    end
  end
  def world_to_local(pos)
    region = [pos[0] / REGION_SIZE, nil, pos[2] / REGION_SIZE]
    t = [pos[0] - (region[0] * REGION_SIZE), pos[2] - (region[2] * REGION_SIZE)]
    chunk = [t[0] / CHUNK_SIZE, nil, t[1] / CHUNK_SIZE]
    block = [t[0] - (chunk[0] * CHUNK_SIZE), pos[1], t[1] - (chunk[2] * CHUNK_SIZE)]
    Coordinate.new(region, chunk, block)
  end

  def block_at(x, y, z)
    coord = world_to_local [x, y, z]
    chunk = chunk_at(coord)
    chunk[coord.block.z, coord.block.x, coord.block.y]
  end

  def chunk_at(coord)
    if chunk = @chunk_cache[[coord.region, coord.chunk]]
      return chunk
    else
      region = region_at(coord)
      chunk = region.chunk(coord.chunk.z, coord.chunk.x)
      if not chunk
        raise "No chunk found at #{coord}"
      end
      @chunk_cache[[coord.region, coord.chunk]] = chunk
      return chunk
    end
  end

  def region_at(coord)
    if region = @region_cache[coord.region]
      return region
    else
      path = "#{@path}/region/r.#{coord.region.x}.#{coord.region.z}.mcr"
      region = RubyCraft::Region.fromFile(path)
      if not region
        raise "No region found at #{coord}"
      end
      @region_cache[coord.region] = region
      return region
    end
  end

  def visible?(x, y, z)
    (x-1..x+1).each do |i|
      (y-1..y+1).each do |j|
        (z-1..z+1).each do |k|
          block = block_at(i, j, k)
          if block.name == 'air'
            return true
          end
        end
      end
    end
    false
  end
end 

class Mcr2Json
  WORLD_PATH = '/home/cyndis/.spoutcraft/saves/DMCR'

  def initialize(world_path)
    @world = Mcr2Json::World.new(world_path)
  end

  # origin and extents in [x, y, z]
  # box is x,z centered in origin, y specifies bottom layer
  def convert(origin, extents, camera_pos=nil, camera_lookat=nil, fov = 90.0,
              aspect = 1920/1080.0)
    json = {'scene' => []}

    ((origin.x - extents.x / 2)..(origin.x + extents.x / 2)).each do |x|
      (origin.y..(origin.y+extents.y)).each do |y|
        ((origin.z - extents.z / 2)..(origin.z + extents.z / 2)).each do |z|
          next if not @world.visible?(x, y, z)

          scene_pos = [x - origin.x,
                       y - origin.y,
                       z - origin.z]

          obj = Primitives.make(scene_pos, @world.block_at(x,y,z))
          json['scene'] << obj if obj
        end
      end
    end

    json['scene'] << Primitives.make_sun(extents)

    if (not camera_pos)
      camera_pos = [extents.x / 2.0, extents.y * 3.0 / 4.0, extents.z / 2.0]
    else
      camera_pos = [camera_pos.x - origin.x,
                    camera_pos.y - origin.y,
                    camera_pos.z - origin.z]
    end
    if (not camera_lookat)
      camera_lookat = [-extents.x / 2.0, 0, -extents.z / 2.0]
    else
      camera_lookat = [camera_lookat.x - origin.x,
                       camera_lookat.y - origin.y,
                       camera_lookat.z - origin.z]
    end
    json['camera'] = {
      'position' => camera_pos,
      'look_at' => camera_lookat,
      'fov' => fov,
      'aspect' => aspect
    }

    return JSON.pretty_generate(json)
  end
end

class Mcr2Json::UI
  def self.str2vecI(str)
    str.split(',').map { |c| c.to_i }
  end

  def self.str2vecF(str)
    str.split(',').map { |c| c.to_f }
  end

  def self.run
    path = ARGV.shift
    if not File.readable?("#{path}/level.dat")
      usage
    end
    origin = str2vecI(ARGV.shift) rescue usage
    extents = str2vecI(ARGV.shift) rescue usage
    camera_pos = str2vecF(ARGV.shift) rescue nil
    camera_lookat = str2vecF(ARGV.shift) rescue nil
    fov = Float(ARGV.shift) rescue 90.0
    aspect = Float(ARGV.shift) rescue 1920/1080.0

    mj = Mcr2Json.new(path)
    puts mj.convert(origin, extents, camera_pos, camera_lookat, fov, aspect)
  end

  def self.usage
    puts "Usage: ruby mcr2json.rb <world path> <origin> <extents> [camera_pos]"
    puts "                          [camera_lookat] [fov] [aspect ratio]"
    puts
    puts "Origin, extents, camera_pos and camera_lookat are specified as x,y,z"
    puts "  in minecraft coordinates."
    puts "The rendered cube"
    puts "- is centered on origin on z and x axises"
    puts "- has it's bottom layer on origin's y coordinate"
    puts "- has edges the length of x,y,z as specified in extents"
    puts "- can span multiple chunks and/or regions"
    puts "Fov is specified in degrees."
    puts "Default fov is 90.0, default aspect ratio is 1920/1080."
    puts "Output is to stdout."
    exit
  end
end

if (__FILE__ == $0)
  if (ENV['HOSTNAME'] == 'katsura' and ARGV.empty?)
    mj = Mcr2Json.new(Mcr2Json::WORLD_PATH)
    puts mj.convert([-110, 60, 8], [100, 20, 100])
  else
    Mcr2Json::UI.run
  end
end
