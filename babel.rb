$LOAD_PATH << File.dirname(__FILE__)

require 'trollop' # for command parsers

require 'arch/x86'

require 'models/binary'
require 'models/workspace'
require 'models/view'

require 'ui'


HOST = ARGV[0] || "http://localhost:9292"

ui = Ui.new("h2gb> ")

ui.register_command('test',
  Trollop::Parser.new do
    banner("Print stuff to the terminal")
  end,
  Proc.new do |opts, optval|
    # TODO: Give the ability to run tests
    require 'test'
  end
)


loop do
  ui.go()
end


