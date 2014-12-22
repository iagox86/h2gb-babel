# ui_binary.rb
# By Ron Bowes
# Created December 12, 2014

require 'analyzer/analyzer'
require 'ui/ui'
require 'ui/babel_ui_workspace'

class BabelUiBinary
  def initialize(binary_id)
    @binary = Binary.find(binary_id)
    @binary_id = binary_id
  end

  def BabelUiBinary.go(binary_id)
    BabelUiBinary.new(binary_id).go()
  end

  def go()
    binary_ui = Ui.new("h2gb #{@binary.o[:name]}> ")

    binary_ui.register_command("back", "Back to the base menu") do
      return
    end

    create_parser = Trollop::Parser.new do
      banner("Create a workspace (Usage: create <name>)")
      opt :u, "Interact with the workspace after creating it"
    end

    binary_ui.register_command("create", create_parser) do |opts, optval|
      if(optval.nil? || optval == '')
        raise(Trollop::HelpNeeded)
      end

      workspace = Workspace.create(:binary_id => @binary_id, :name => optval)
      puts(workspace.o)

      if(opts[:u])
        BabelUiWorkspace.go(@binary_id, workspace.o[:workspace_id])
      end
    end

    binary_ui.register_command('workspaces', "List workspaces") do
      workspaces = Workspace.all(:binary_id => @binary_id).o[:workspaces]
      if(workspaces.count() > 0)
        workspaces.each do |b|
          puts(b)
        end
      else
        puts("No workspaces! Why don't you create one?")
      end
    end

    binary_ui.register_command("use", "Interact with the workspace (Usage: use <id>)") do |opts, optval|
      BabelUiWorkspace.go(@binary_id, optval.to_i)
    end

    analyze_parser = Trollop::Parser.new do
      banner("Create a workspace (Usage: analyze [name])")
      opt :u, "Interact with the workspace after creating it"
    end

    binary_ui.register_command("analyze", analyze_parser) do |opts, optval|
      name = "workspace TODO[date]"
      if(!optval.nil? && optval != '')
        name = optval
      end

      workspace = Workspace.create(:binary_id => @binary_id, :name => name)
      puts(workspace.o)

      Analyzer.analyze(@binary_id, workspace.o[:workspace_id])
      workspace.save()

      if(opts[:u])
        BabelUiWorkspace.go(@binary_id, workspace.o[:workspace_id])
      end
    end

    loop do
      binary_ui.go()
    end
  end
end
