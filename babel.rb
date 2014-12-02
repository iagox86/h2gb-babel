$LOAD_PATH << File.dirname(__FILE__)

require 'trollop' # for command parsers

require 'arch/x86'

require 'models/binary'
require 'models/workspace'
require 'models/view'

require 'ui'


HOST = ARGV[0] || "http://localhost:9292"

ui = Ui.new("h2gb> ")

ui.register_command('test', "Run tests") do |opts, optval|
  # TODO: Give the ability to run tests (I don't want to mes with test.rb since I'm not at HEAD)
  require 'test'
end

ui.register_command('binaries', "List binaries") do
  binaries = Binary.all().o[:binaries]
  binaries.each do |b|
    puts(b)
  end
end

loop do
  ui.go()
end


