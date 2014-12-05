$LOAD_PATH << File.dirname(__FILE__)

require 'trollop' # for command parsers

require 'arch/x86'

require 'models/binary'
require 'models/workspace'
require 'models/view'

require 'test'
require 'ui'


HOST = ARGV[0] || "http://localhost:9292"

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
end

COMMANDS = [
  "binaries",
]
COMMANDS.each do |c|
  base_ui.run(c)
end

loop do
  base_ui.go()
end


