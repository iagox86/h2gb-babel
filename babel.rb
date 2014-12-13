$LOAD_PATH << File.dirname(__FILE__)

require 'babel_ui_base'

HOST = ARGV[0] || "http://localhost:9292"

ui = BabelUiBase.new()
ui.go()

