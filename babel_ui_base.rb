# ui_base.rb
# By Ron Bowes
# Created December 12, 2014

require 'test'
require 'ui'
require 'babel_ui_binary'

class BabelUiBase
  def initialize()

  end

  def go()
    base_ui = Ui.new("h2gb> ")

    base_ui.register_command('test', "Run tests") do |opts, optval|
      Test.test()
    end

    base_ui.register_command('binaries', "List binaries") do
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

    base_ui.register_command("upload", upload_parser) do |opts, optval|
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
        BabelUiBinary.go(binary.o[:binary_id])
      end
    end

    edit_parser = Trollop::Parser.new do
      banner("Edit a binary (Usage: edit <id>)")
      opt :n, "Give the uploaded file a different name (by default, uses the filename)", :type => :string, :required => false
      opt :c, "Add a comment to the file", :type => :string, :required => false
      opt :f, "Change the file data to the specified file's", :type => :string, :required => false
    end

    base_ui.register_command("edit", edit_parser) do |opts, optval|
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

    base_ui.register_command("delete", "Deletes the specified binary (Usage: delete <id>)") do |opts, optval|
      if(optval.nil? || !(optval =~ /^[0-9]+$/))
        raise(Trollop::HelpNeeded)
      end

      puts Binary.find(optval.to_i).delete().o
    end

    base_ui.register_command("use", "Interact with the binary (Usage: use <id>)") do |opts, optval|
      BabelUiBinary.go(optval.to_i)
    end

    loop do
      base_ui.go()
    end
  end
end
