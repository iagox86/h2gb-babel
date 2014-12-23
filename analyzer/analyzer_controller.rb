# analyzer_controller.rb
# By Ron Bowes
# Created December 22, 2014

require 'analyzer/analyzer_node'
require 'analyzer/analyzer_segment'

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

    return segment
  end

  def add_node(segment_name, node)
    segment = @segments[segment_name]
    segment.add_node(node)

    return node
  end

  def push(sink)
    @segments.each_pair do |segment_name, segment|
      segment.push(sink)
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
