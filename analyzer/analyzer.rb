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

      arch = Intel.new(segment.data, Intel::X86, segment.address)
      addr = 0
      completed = {}

      while(queue.length > 0)
        puts("Queue: #{queue.map() { |a| "%04x" % a }.join(", ")}")

        # Get the address
        addr = queue.shift()

        # Check if it's already completed (TODO: There's probably a better way)
        if(completed[addr])
          next
        end

        # Disassemble the address
        dis = arch.disassemble(addr)

        # Create the node and add it to the segment
        segment.add_node(AnalyzerNode.new(addr, dis[:type], dis[:length], dis[:value], [])) # TODO: refs + details

        # Mark the address as completed
        completed[addr] = true

        # Queue up its references
        queue += dis[:references]
      end
    end

    controller.push(sink)
  end
end
