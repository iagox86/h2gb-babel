# ui_workspace.rb
# By Ron Bowes
# Created December 12, 2014

class BabelUiWorkspace
  def initialize(binary_id, workspace_id)
    @binary_id = binary_id
    @binary = Binary.find(@binary_id)
    @workspace_id = workspace_id
    @workspace = Workspace.find(@workspace_id)
  end

  def BabelUiWorkspace.go(binary_id, workspace_id)
    BabelUiWorkspace.new(binary_id, workspace_id).go()
  end

  def go()
    workspace_ui = Ui.new("h2gb #{@binary.o[:name]}/#{@workspace.o[:name]}> ")

    workspace_ui.register_command("back", "Back to the binary menu") do
      return
    end

    segments_parser = Trollop::Parser.new do
      banner("List segments")
      opt :d, "List the data, as well (hex encoded)"
    end

    workspace_ui.register_command("segments", segments_parser) do |opts, optval|
      if(opts[:d])
        segments = @workspace.get_all_segments(:with_data => true)
        segments.each do |s|
          s[:data] = s[:data].unpack("H*")
        end
      else
        segments = @workspace.get_all_segments()
      end
      segments.each do |s|
        puts(s.inspect)
      end
    end

    loop do
      workspace_ui.go()
    end
  end
end

