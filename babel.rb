$LOAD_PATH << File.dirname(__FILE__)

require 'trollop' # for command parsers

require 'arch/x86'

require 'models/binary'
require 'models/workspace'

require 'test'
require 'ui'
require 'babel_ui_base'
require 'babel_ui_binary'
require 'babel_ui_workspace'

HOST = ARGV[0] || "http://localhost:9292"

ui = BabelUiBase.new()
ui.go()

