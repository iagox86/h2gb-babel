$LOAD_PATH << File.dirname(__FILE__)

HOST = ARGV[0] || "http://localhost:9292"

require 'active_rest_client'

require 'active_rest_extras'
require 'models/binary'
require 'models/view'
require 'models/workspace'

puts()
puts("** CREATE A BINARY")
binary = Binary.create(
  :name => "Binary Test",
  :comment => "Test binary",
  :data => Base64.encode64("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"),
)
if(!binary.id)
  puts("A valid binary wasn't returned!")
  puts("We got: #{binary.inspect}")
  exit
end
puts(binary.inspect)
puts("BINARY_ID: %d" % binary.id)

puts()
puts("** GET ALL BINARIES (should include the new one)")
all_binaries = Binary.all()
good = false
all_binaries.binaries.each do |b|
  if(b.id == binary.id)
    good = true
    puts("  * Found our new binary!")
  end
end
if(!good)
  puts("Couldn't find out new binary!")
  exit
end

puts()
puts("** FIND A BINARY")
binary_again = Binary.find(:binary_id => binary.id)
puts(binary_again.inspect)
binary = binary_again

# TODO: Test the update

puts()
puts("** CREATE A WORKSPACE")
workspace = Workspace.create(:binary_id => binary.id, :name => "test workspace")
puts(workspace.inspect)
if(!workspace.id)
  puts("A valid workspace wasn't returned!")
  puts("We got: #{workspace.inspect}")
  exit
end
puts("WORKSPACE_ID: %d" % workspace.id)

puts()
puts("** LIST ALL WORKSPACES")
workspaces = Workspace.all(:binary_id => binary.id)
if(workspaces[:workspaces].count != 1)
  puts("We should have exactly one workspace under our new binary, but we have #{workspaces[:workspaces].length} instead!")
  exit
end
workspaces[:workspaces].each do |w|
  if(w.id != workspace.id)
    puts("The workspace returned by 'all' didn't have the same id as the new workspace!")
    exit
  end
  puts(w.inspect)
end

puts()
puts("** FIND THE WORKSPACE")
workspace = Workspace.find(:workspace_id => workspace.id)
puts(workspace.inspect)

# TODO: Test the update

# TODO: Test the get / set

puts()
puts("** CREATE view")
view = View.create(:workspace_id => workspace.id)
puts(view.inspect)

puts()
puts("** LIST VIEWS")
views = View.all(:workspace_id => workspace.id)
puts(views.inspect)
if(views[:views].count != 1)
  puts("Exactly 1 result wasn't returned as expected! Instead, #{views[:views].count} were returned")
end
views[:views].each do |m|
  if(m.id != view.view_id)
    puts("The view returned by 'all' didn't have the same id as the new view!")
    puts(m.id)
    puts(view.view_id)
    exit
  end
end

puts()
puts("** FIND VIEW")
view = View.find(:view_id => view.view_id)
puts(view.inspect)


# TODO: Create segments / nodes

puts()
puts("** DELETING VIEW")
puts view.delete().inspect()

puts("** DELETE THE WORKSPACE")
puts workspace.delete().inspect()

puts()
puts("** DELETE THE BINARY")
puts binary.delete().inspect()
