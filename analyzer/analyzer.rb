# analyzer.rb
# By Ron Bowes
# Created 2014-12-12

require 'models/binary'
require 'models/workspace'

require 'analyzer/formats/auto_format'
require 'analyzer/formats/elf'
require 'analyzer/formats/pe'
require 'analyzer/formats/raw'

require 'analyzer/arch/intel'

require 'pp' # TODO: debug

class Analyzer
  # TODO: Get rid of network dependencies so I can test this
  def Analyzer.analyze(binary_id, workspace_id)
    binary = Binary.find(binary_id, :with_data => true)
    workspace = Workspace.find(workspace_id)

    puts("Analyzing: #{binary.inspect}")
    puts("Analyzing: #{workspace.inspect}")

    file = AutoFormat.parse(binary.o[:data])

    file[:header].each_pair do |key, value|
      workspace.set_property(key, value)
    end

    file[:segments].each do |segment|
      # Create the segment
      workspace.new_segment(
        segment[:name],
        segment[:address],
        segment[:data],
        {
          :file_address => segment[:file_address]
        }
      )

      # Do the actual disassembly
      queue = [file[:header][:entrypoint]]

      arch = Intel.new(segment[:data], Intel::X86, segment[:address])
      addr = 0
      nodes = {}

      while(queue.length > 0)
        puts("Queue: #{queue.map() { |a| "%04x" % a }.join(", ")}")

        # Get the address
        addr = queue.shift()

        # Check if it's already completed (TODO: There's probably a better way)
        if(nodes[addr])
          next
        end

        # Disassemble the address
        dis = arch.disassemble(addr)

        nodes[addr] = {
          :address    => addr,
          :type       => dis[:type],
          :length     => dis[:length],
          :value      => dis[:value],
          :details    => dis[:details],
          :refs       => []#dis[:references] # TODO: FIXME
        }

        # Queue up its references
        queue += dis[:references]
      end

      workspace.new_nodes(segment[:name], nodes.values)
    end
  end
end
