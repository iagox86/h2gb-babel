# analyzer.rb
# By Ron Bowes
# Created 2014-12-12

require 'models/binary'
require 'models/workspace'

require 'formats/auto_format'
require 'formats/elf'
require 'formats/pe'
require 'formats/raw'

require 'arch/intel'

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
      arch = Intel.new(segment[:data], Intel::X86, segment[:address])
      addr = 0
      nodes = []
      while(addr < segment[:data].length) do
        dis = arch.disassemble(addr)

        nodes << {
          :address    => addr,
          :type       => dis[:type],
          :length     => dis[:length],
          :value      => dis[:value],
          :details    => dis[:details],
          :references => dis[:references]
        }

        addr += dis[:length]
      end

      workspace.new_nodes(segment[:name], nodes)
    end
  end
end
