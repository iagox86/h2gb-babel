$LOAD_PATH << File.dirname(__FILE__)

require 'trollop' # for command parsers

require 'arch/x86'

require 'models/binary'
require 'models/workspace'

require 'test'
require 'ui'
require 'ui_base'
require 'ui_binary'
require 'ui_workspace'

HOST = ARGV[0] || "http://localhost:9292"

ui = UiBase.new()
ui.go()

