# memory.rb
# By Ron Bowes
# Created October 6, 2014

class MemorySegment
  attr_reader :name, :real_addr, :file_addr, :data

  def initialize(name, real_addr, file_addr, data)
    @name      = name
    @real_addr = real_addr
    @file_addr = file_addr
    @data      = data.split(//)
  end

  def length
    return @data.length
  end

  def contains?(addr, len)
    return (addr >= @real_addr) && ((addr + len - 1) < (@real_addr + length()))
  end

  def contains_node?(node)
    return contains?(node.real_addr, node.length)
  end

  def each_address()
    @real_addr.upto(length() - 1) do |a|
      yield(address)
    end
  end

  def to_s()
    return "Segment: %s (0x%08x - 0x%08x)" % [@name, @real_addr, @real_addr + length()]
  end
end

class Memory
  class SegmentNotFoundException < StandardError
  end
  class SegmentationException < StandardError
  end
  class OverlappingSegmentException < StandardError
  end

  def initialize()
    @memory_bytes = []
    @memory_nodes = []
    @segments     = {}

    @actions = []
  end

#  def find_segment(addr)
#    @segments.each_pair do |_, s|
#      if(addr >= s.real_addr && addr < (s.real_addr + s.length))
#        return s
#      end
#    end
#
#    raise SegmentationException
#  end

  def remove_node(node, rewindable = true)
    node[:address].upto(node[:address] + node[:length] - 1) do |addr|
      @memory_nodes[addr] = nil
    end

    if(rewindable)
      @actions << { :type => :remove, :node => node }
    end
  end

  def undefine(addr, len)
    addr.upto(addr + len - 1) do |a|
      if(!@memory_nodes[a].nil?)
        remove_node(@memory_nodes[a])
      end
    end
  end

  def add_node_internal(node, rewindable = true)
    # Make sure there's enough room
    node[:address].upto(node[:address]+node[:length] - 1) do |addr|
      # There's no memory
      if(@memory_bytes[addr].nil?)
        raise SegmentationException
      end
    end

    # Make sure the nodes are undefined
    undefine(node[:address], node[:length])

    # Save the node to memory
    node[:address].upto(node[:address]+node[:length] - 1) do |addr|
      @memory_nodes[addr] = node
    end

    if(rewindable)
      @actions << { :type => :add, :node => node }
    end
  end

  def add_node(type, address, length, details, refs = [], rewindable = true)
    return add_node_internal({
      :type    => type,
      :address => address,
      :length  => length,
      :details => details,
      :refs    => refs,
    }, rewindable)
  end

  def rewind(steps = 1)
    0.upto(steps - 1) do
      action = @actions.pop

      if(action[:type] == :add)
        remove_node(action[:node], false)
      elsif(action[:type] == :remove)
        add_node_internal(action[:node], false)
      else
        puts("Unknown action: #{action[:type]}")
        raise NotImplementedException
      end
    end
  end

  def mount_segment(segment)
    # Make sure the memory isn't already in use
    memory = @memory_nodes[segment.real_addr, segment.length]
    if(!(memory.nil? || memory.compact().length() == 0))
      raise OverlappingSegmentException
    end

    # Keep track of the mount so we can unmount later
    @segments[segment.name] = segment

    # Insert the data
    @memory_bytes[segment.real_addr, segment.length] = segment.data
  end

  def unmount_segment(name)
    # Clear the memory for the segment
    segment = @segments['name']
    if(segment.nil?)
      raise SegmentNotFoundException
    end

    # Undefine its entire space
    undefine(segment.real_addr, segment.length - 1)

    # Delete the data
    @memory_bytes[segment.real_addr, segment.length] = [nil] * segment.length

    # Delete it
    @segments.delete(name)
  end

  def each_node()
    i = 0

    while(i < @memory_bytes.length) do
      if(@memory_nodes[i].nil? && @memory_bytes[i].nil?)
        # We're between segments, do nothing
        i += 1
      elsif(@memory_nodes[i].nil?)
        # We're not in a node, but we do have valid bytes/memory
        yield i, nil
        i += 1
      else
        # We're in a node
        yield i, @memory_nodes[i]
        i += @memory_nodes[i][:length]
      end
    end
  end

  def to_s()
    s = ""

    @segments.each do |segment|
      s += segment.to_s + "\n"
    end

    each_node do |addr, node|
      if(node.nil?)
        # We're not in a node, but we do have valid bytes/memory
        s += "0x%08x %02x <undefined>\n" % [addr, @memory_bytes[addr].ord]
      else
        # We're in a node
        s += "0x%08x %s\n" % [addr, node[:details]]
      end
    end

    return s
  end

  def get_bytes_at(addr, length)
    return (@memory_bytes[addr, length].map do |c| c.chr end).join
  end

  def get_dword_at(addr)
    return get_bytes_at(addr, 4).unpack("I")
  end

  def get_word_at(addr)
    return get_bytes_at(addr, 2).unpack("S")
  end

  def get_byte_at(addr)
    return get_bytes_at(addr, 1).ord
  end

  def get_nodes()
    nodes = []

    each_node do |addr, node|
      if(node.nil?)
        nodes << {
          :type    => 'undefined',
          :address => addr,
          :length  => 1,
          :details => {},
          :refs    => [],
        }
      else
        nodes << {
          :type    => node[:type],
          :address => node[:address],
          :length  => node[:length],
          :details => node[:details],

          # TODO
          :file_address => "TODO",
          :xrefs        => ["TODO"],
        }
      end
    end

    return nodes
  end
end

m = Memory.new()

m.mount_segment(MemorySegment.new("s1", 0x1000, 0x0000, "A" * 16))
m.mount_segment(MemorySegment.new("s2", 0x2000, 0x0000, "B" * 8))

puts("Inserting new node")
m.add_node('dword', 0x1000, 4, { value: m.get_dword_at(0x1000) })
m.add_node('word',  0x1004, 2, { value: m.get_word_at(0x1004) })
m.add_node('byte', 0x1008, 1, { value: m.get_byte_at(0x1008) })

puts(m.to_s)

m.add_node('dword', 0x1000, 4, { value: m.get_dword_at(0x1000) })
m.add_node('word',  0x1004, 4, { value: m.get_dword_at(0x1004) })
m.add_node('byte',  0x1008, 4, { value: m.get_dword_at(0x1008) })

puts(m.to_s)
puts()

puts(m.get_nodes.inspect)
puts()

while true do
  m.rewind(1)
  puts(m.to_s)
  gets()
end
