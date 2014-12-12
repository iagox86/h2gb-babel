$LOAD_PATH << File.dirname(__FILE__)

require 'trollop' # for command parsers

require 'arch/x86'

require 'models/binary'
require 'models/workspace'
require 'models/view'

require 'test'
require 'ui'

HOST = ARGV[0] || "http://localhost:9292"

def do_binary_ui(binary_id)
  binary = Binary.find(binary_id)

  binary_ui = Ui.new("h2gb #{binary.o[:name]}> ") do
    register_command("back", "Back to the base menu") do
      return
    end

    register_command("test", "test") do
      puts("TESTING")
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
      binaries.each do |b|
        puts(b)
      end
    end

    register_command("use", "Interact with the binary") do
      puts("Use!")
    end

    upload_parser = Trollop::Parser.new do
      banner("Upload a binary (Usage: upload <path>)")
      opt :c, "Add a comment to the file", :type => :string, :required => false
      opt :n, "Give the uploaded file a different name (by default, uses the filename)", :type => :string, :required => false
    end

    register_command("upload", upload_parser) do |opts, optarg|
      if(optarg.nil? || optarg == '')
        raise(Trollop::HelpNeeded)
      end
      binary = Binary.create(
        :name    => opts[:n] || File.basename(optarg),
        :comment => opts[:c],
        :data    => IO.read(optarg),
      )

      puts(binary.o)
    end

    edit_parser = Trollop::Parser.new do
      banner("Edit a binary (Usage: edit <id>)")
      opt :n, "Give the uploaded file a different name (by default, uses the filename)", :type => :string, :required => false
      opt :c, "Add a comment to the file", :type => :string, :required => false
      opt :f, "Change the file data to the specified file's", :type => :string, :required => false
    end

    register_command("edit", edit_parser) do |opts, optarg|
      if(optarg.nil? || !(optarg =~ /^[0-9]+$/))
        raise(Trollop::HelpNeeded)
      end

      b = Binary.find(optarg.to_i, :with_data => true)
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

    register_command("delete", "Deletes the specified binary (Usage: delete <id>)") do |opts, optarg|
      if(optarg.nil? || !(optarg =~ /^[0-9]+$/))
        raise(Trollop::HelpNeeded)
      end

      puts Binary.find(optarg.to_i).delete().o
    end

    register_command("use", "Use a binary (Usage: use <id>)") do |opts, optarg|
      do_binary_ui(optarg.to_i)
    end
  end

  loop do
    base_ui.go()
  end
end

do_base_ui()

