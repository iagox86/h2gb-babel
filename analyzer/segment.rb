# segment.rb
# By Ron Bowes
# Created December 22, 2014

class AnalyzerController
  def initialize(sink)
    @segments = {}

    pull(sink)
  end

  def add_segment(segment)
    # TODO: Still not exactly sure how to deal with segments
#    if(!@segments[segment.name].nil?)
#      raise(Exception, "That segment already exists")
#    end
#
    @segments[segment.name] = segment
  end

  def add_node(segment_name, node)
    segment = @segments[segment_name]
    segment.add_node(node)
  end

  def push(sink)
    @segments.each_pair do |segment_name, segment|
      segment.sync(sink)
    end
  end

  def pull(sink, since = 0)
    result = sink.get_all_segments(:since => since, :with_data => true, :with_nodes => true)

    result.each_pair do |segment_name, segment|
      add_segment(AnalyzerSegment.new(segment_name, segment[:address], segment[:data], false))
      segment[:nodes].each_pair do |address, node|
        add_node(segment_name, AnalyzerNode.new(address, node[:type], node[:length], node[:value], node[:refs], false))
      end
    end
  end
end

class AnalyzerSegment
  attr_accessor :name

  def initialize(name, address, data, needs_creating = true)
    @name      = name
    @address   = address
    @data      = data

    @needs_creating = needs_creating

    @nodes     = {}
  end

  def add_node(node)
    node.address.upto(node.address + node.length - 1) do |address|
      @nodes.delete(address)
    end

    # Save the new node
    @nodes[node.address] = node
  end

  def sync(sink)
    # If it needs to be created, create it
    if(@needs_creating)
      sink.new_segment(@name, @address, @data, {})
      @needs_creating = false
    end
    sink.new_nodes(@name, @nodes.values.select() { |x| x.dirty? }.map() { |x| x.to_json(true) })
  end
end

class AnalyzerNode
  attr_reader :address, :length
  attr_reader :dirty

  def initialize(address, type, length, value, refs, dirty = true)
    @address = address
    @type    = type
    @length  = length
    @value   = value
    @refs    = refs

    @dirty = dirty
  end

  def dirty?()
    return @dirty
  end

  def to_json(cleanup = false)
    if(cleanup)
      @dirty = false
    end

    return {
      :address => @address,
      :type    => @type,
      :length  => @length,
      :value   => @value,
      :refs    => @refs,
    }
  end
end
