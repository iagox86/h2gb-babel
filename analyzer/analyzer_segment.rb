# analyzer_segment.rb
# By Ron Bowes
# Created December 22, 2014

class AnalyzerSegment
  attr_accessor :name, :address, :data

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

  def push(sink)
    # If it needs to be created, create it
    if(@needs_creating)
      sink.new_segment(@name, @address, @data, {})
      @needs_creating = false
    end
    sink.new_nodes(@name, @nodes.values.select() { |x| x.dirty? }.map() { |x| x.to_json(true) })
  end
end
