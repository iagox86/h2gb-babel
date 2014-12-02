require 'readline'
require 'shellwords' # parsing commands
require 'trollop' # parsing commands

class Ui
  def initialize(prompt = "> ", *params)
    @prompt = prompt

    @commands = {}

    register_command('', '') do
    end

    register_command('echo', "Print stuff to the terminal") do |opt, optval|
      puts(optval)
    end

    register_command('exit', "Exit", :aliases => ['quit', 'q']) do
      exit
    end

    register_command('help', "Shows a help menu", :aliases => 'q') do |opts, optval|
      puts("Here are the available commands, listed alphabetically:")
      @commands.keys.sort.each do |name|
        # Don't display the empty command
        if(name != "")
          puts("- #{name}")
        end
      end

      puts("For more information, --help can be passed to any command")
    end

    # This runs the block passed in, though I don't exactly understand how.
    # Copied from Trollop
    if(!proc.nil?)
      (class << self; self; end).class_eval do
        define_method :cloaker_, proc
        meth = instance_method :cloaker_
        remove_method :cloaker_
        meth
      end.bind(self).call(*params)
    end
  end

  def register_command(name, parser, params = {})
    result = @commands.delete(name)

    if(parser.is_a?(String))
      parser = Trollop::Parser.new do banner(parser) end
    end

    @commands[name] = {
      :parser => parser,
      :proc   => proc,
    }

    return result
  end

  def process_line(line)
    # If the line starts with a '!', just pass it to a shell
    if(line[0] == '!')
      system(line[1..-1])
      return
    end

    begin
      args = Shellwords.shellwords(line)
    rescue Exception => e
      $stderr.puts("Parse failed: #{e}")
      return
    end

    if(args.length > 0)
      command = args.shift
    else
      command = ""
      args = []
    end

    if(@commands[command].nil?)
      puts("Unknown command: #{command}")
    else
      begin
        command = @commands[command]
        command[:parser].stop_on("--")
        opts = command[:parser].parse(args)
        optval = ""
        optarr = command[:parser].leftovers
        if(!optarr.nil?())
          if(optarr[0] == "--")
            optarr.shift()
          end
          optval = optarr.join(" ")
        end

        command[:proc].call(opts, optval)
      rescue Trollop::CommandlineError => e
        $stderr.puts("ERROR: #{e}")
      rescue Trollop::HelpNeeded => e
        command[:parser].educate
      end
    end
  end

  def go()
    run(Readline.readline(@prompt, true))
  end

  def run(line)
    # If we hit EOF, terminate
    if(line.nil?)
      puts()
      exit
    end

    # Otherwise, process the line
    begin
      process_line(line)
    rescue SystemExit
      exit
    rescue Exception => e
      $stderr.puts("There was an error processing the line: #{e}")
      $stderr.puts("If you think it was my fault, please submit a bug report with the following stacktrace:")
      $stderr.puts("")
      $stderr.puts(e.backtrace)
    end
  end

  def set_prompt(prompt)
    @prompt = prompt
  end
end
