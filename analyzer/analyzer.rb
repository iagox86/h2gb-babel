# analyzer.rb
# By Ron Bowes
# Created 2014-12-12

require 'analyzer/formats/auto_format'
require 'analyzer/formats/elf'
require 'analyzer/formats/pe'
require 'analyzer/formats/raw'

require 'analyzer/arch/intel'
require 'analyzer/analyzer_controller'
require 'analyzer/analyzer_node'
require 'analyzer/analyzer_segment'

require 'pp' # TODO: debug

class Analyzer
  # The sink should have the functions:
  #new_segment(name, address, data, details, params = {})
  #new_segments(segments, params = {})
  #new_node(segment_name, address, type, length, value, details, references, params = {})
  #new_nodes(segment_name, nodes, params = {})
  def Analyzer.analyze(data, sink)
    file = AutoFormat.parse(data)
    controller = AnalyzerController.new(sink)

    file[:header].each_pair do |key, value|
      sink.set_property(key, value)
    end

    file[:segments].each do |s|
      # Create the segment
      segment = AnalyzerSegment.new(s[:name], s[:address], s[:data])
      controller.add_segment(segment)

      # Do the actual disassembly
      queue = [file[:header][:entrypoint]]
      #queue = []

      arch = Intel.new(segment.data, Intel::X86, segment.address)
      addr = 0
      completed = {}

      while(queue.length > 0)
        puts("Queue: #{queue.map() { |a| "0x%08x" % a }.join(", ")}")

        # Get the address
        addr = queue.shift()

        # Check if it's already completed (TODO: There's probably a better way)
        if(completed[addr])
          next
        end

        # Disassemble the address
        dis = arch.disassemble(addr)

        if(!dis.nil?)
          # Create the node and add it to the segment
          segment.add_node(AnalyzerNode.new(addr, dis[:type], dis[:length], dis[:value], [])) # TODO: refs + details

          # Queue up its references
          queue += dis[:references]
        else
          puts("Warning: Couldn't disassemble address 0x%08x" % addr)
        end

        # Mark the address as completed
        completed[addr] = true

      end
    end

    controller.push(sink)
  end
end
