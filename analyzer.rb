# analyzer.rb
# By Ron Bowes
# Created 2014-12-12

require 'models/binary'
require 'models/workspace'

require 'formats/auto_format'
require 'formats/elf'
require 'formats/pe'
require 'formats/raw'

require 'pp' # TODO: debug

class Analyzer
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
      workspace.new_segment(
        segment[:name],
        segment[:address],
        segment[:file_address],
        segment[:data],
      )
    end
  end
end
