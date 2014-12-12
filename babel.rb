$LOAD_PATH << File.dirname(__FILE__)

require 'trollop' # for command parsers

require 'arch/x86'

require 'models/binary'
require 'models/workspace'

require 'test'
require 'ui'

HOST = ARGV[0] || "http://localhost:9292"

def do_workspace_ui(binary_id, workspace_id)
  binary = Binary.find(binary_id)
  workspace = Workspace.find(workspace_id)

  workspace_ui = Ui.new("h2gb #{binary.o[:name]}/#{workspace.o[:name]}> ") do
    register_command("back", "Back to the binary menu") do
      return
    end
  end

  loop do
    workspace_ui.go()
  end
end

def do_binary_ui(binary_id)
  binary = Binary.find(binary_id)

  binary_ui = Ui.new("h2gb #{binary.o[:name]}> ") do
    register_command("back", "Back to the base menu") do
      return
    end

    create_parser = Trollop::Parser.new do
      banner("Create a workspace (Usage: create <name>)")
      opt :u, "Interact with the workspace after creating it"
    end

    register_command("create", create_parser) do |opts, optval|
      if(optval.nil? || optval == '')
        raise(Trollop::HelpNeeded)
      end

      workspace = Workspace.create(:binary_id => binary_id, :name => optval)
      puts(workspace.o)

      if(opts[:u])
        do_workspace_ui(binary_id, workspace.o[:workspace_id])
      end
    end

    register_command('workspaces', "List workspaces") do
      workspaces = Workspace.all(:binary_id => binary_id).o[:workspaces]
      if(workspaces.count() > 0)
        workspaces.each do |b|
          puts(b)
        end
      else
        puts("No workspaces! Why don't you create one?")
      end
    end

    register_command("use", "Interact with the workspace (Usage: use <id>)") do |opts, optval|
      do_workspace_ui(binary_id, workspace.o[:workspace_id])
    end

    analyze_parser = Trollop::Parser.new do
      banner("Create a workspace (Usage: analyze [name])")
      opt :u, "Interact with the workspace after creating it"
    end

    register_command("analyze", analyze_parser) do
    end
  end

  loop do
    binary_ui.go()
  end
end

def do_base_ui()
  base_ui = Ui.new("h2gb> ") do
    register_command('test', "Run tests") do |opts, optval|
      Test.test()
    end

    register_command('binaries', "List binaries") do
      binaries = Binary.all().o[:binaries]
      if(binaries.count() > 0)
        binaries.each do |b|
          puts(b)
        end
      else
        puts("No binaries! Why don't you upload one?")
      end
    end

    upload_parser = Trollop::Parser.new do
      banner("Upload a binary (Usage: upload <path>)")
      opt :c, "Add a comment to the file", :type => :string, :required => false
      opt :n, "Give the uploaded file a different name (by default, uses the filename)", :type => :string, :required => false
      opt :u, "Interact with the binary after uploading it"
    end

    register_command("upload", upload_parser) do |opts, optval|
      if(optval.nil? || optval == '')
        raise(Trollop::HelpNeeded)
      end
      binary = Binary.create(
        :name    => opts[:n] || File.basename(optval),
        :comment => opts[:c],
        :data    => IO.read(optval),
      )

      puts(binary.o)

      if(opts[:u])
        do_binary_ui(binary.o[:binary_id])
      end
    end

    edit_parser = Trollop::Parser.new do
      banner("Edit a binary (Usage: edit <id>)")
      opt :n, "Give the uploaded file a different name (by default, uses the filename)", :type => :string, :required => false
      opt :c, "Add a comment to the file", :type => :string, :required => false
      opt :f, "Change the file data to the specified file's", :type => :string, :required => false
    end

    register_command("edit", edit_parser) do |opts, optval|
      if(optval.nil? || !(optval =~ /^[0-9]+$/))
        raise(Trollop::HelpNeeded)
      end

      b = Binary.find(optval.to_i, :with_data => true)
      if(!opts[:n])
        b.o[:name] = opts[:n]
      end
      if(!opts[:c])
        b.o[:comment] = opts[:c]
      end
      if(!opts[:f].nil?)
        b.o[:data] = IO.read(opts[:f])
      end

      puts(b.save().o)
    end

    register_command("delete", "Deletes the specified binary (Usage: delete <id>)") do |opts, optval|
      if(optval.nil? || !(optval =~ /^[0-9]+$/))
        raise(Trollop::HelpNeeded)
      end

      puts Binary.find(optval.to_i).delete().o
    end

    register_command("use", "Interact with the binary (Usage: use <id>)") do |opts, optval|
      do_binary_ui(optval.to_i)
    end
  end

  loop do
    base_ui.go()
  end
end

do_base_ui()

