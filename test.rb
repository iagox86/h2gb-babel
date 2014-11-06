$LOAD_PATH << File.dirname(__FILE__)

HOST = ARGV[0] || "http://localhost:9292"

require 'active_rest_client'

require 'active_rest_extras'
require 'models/binary'
require 'models/view'
require 'models/workspace'

binary_id    = nil
workspace_id = nil
view_id      = nil

begin
  puts()
  puts("** CREATE A BINARY")
  binary = Binary.create(
    :name => "Binary Test",
    :comment => "Test binary",
    :data => Base64.encode64("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"),
  )
  binary_id = binary.binary_id

  if(!binary_id)
    puts("A valid binary wasn't returned!")
    puts("We got: #{binary.inspect}")
    exit
  end
  puts(binary.inspect)
  puts("binary_id: %d" % binary_id)

  puts()
  puts("** GET ALL BINARIES (should include the new one)")
  all_binaries = Binary.all()
  good = false
  all_binaries.binaries.each do |b|
    if(b.binary_id == binary_id)
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
  binary_again = Binary.find(:binary_id => binary_id)
  puts(binary_again.inspect)
  binary = binary_again

  # TODO: Test the update

  puts()
  puts("** CREATE A WORKSPACE")
  workspace = Workspace.create(:binary_id => binary_id, :name => "test workspace")
  puts(workspace.inspect)
  workspace_id = workspace.workspace_id

  if(!workspace_id)
    puts("A valid workspace wasn't returned!")
    puts("We got: #{workspace.inspect}")
    exit
  end
  puts("workspace_id: %d" % workspace_id)

  puts()
  puts("** LIST ALL WORKSPACES")
  workspaces = Workspace.all(:binary_id => binary_id)
  if(workspaces[:workspaces].count != 1)
    puts("We should have exactly one workspace under our new binary, but we have #{workspaces[:workspaces].length} instead!")
    exit
  end
  workspaces[:workspaces].each do |w|
    if(w.workspace_id != workspace_id)
      puts("The workspace returned by 'all' didn't have the same id as the new workspace!")
      exit
    end
    puts(w.inspect)
  end

  puts()
  puts("** FIND THE WORKSPACE")
  workspace = Workspace.find(:workspace_id => workspace_id)
  puts(workspace.inspect)

  puts()
  puts("** UPDATE THE WORKSPACE")
  workspace.name = "new workspace name"
  workspace.save()
  workspace = Workspace.find(:workspace_id => workspace_id)
  puts(workspace.inspect)
  # TODO: Test the update

  # TODO: Test the get / set

  puts()
  puts("** CREATE view")
  view = View.create(:workspace_id => workspace_id)
  puts(view.inspect)
  view_id = view.view_id

  puts()
  puts("** LIST VIEWS")
  views = View.all(:workspace_id => workspace_id)
  puts(views.inspect)
  if(views[:views].count != 1)
    puts("Exactly 1 result wasn't returned as expected! Instead, #{views[:views].count} were returned")
  end
  views[:views].each do |m|
    if(m.view_id != view.view_id)
      puts("The view returned by 'all' didn't have the same id as the new view!")
      puts(m.id)
      puts(view.view_id)
      exit
    end
  end

  puts()
  puts("** FIND VIEW")
  view = View.find(:view_id => view_id)
  puts(view.inspect)


  # TODO: Create segments / nodes

rescue Exception => e
  puts()
  puts("EXCEPTION!!")
  puts(e)
  puts()

  puts("Press 'enter' to continue")
  gets()
ensure

  puts()
  puts("CLEANING UP")
  puts()

  if(!view_id.nil?)
    puts()
    puts("** DELETING VIEW")
    puts(View.find(:view_id => view_id).delete().inspect())
  else
    puts("** NO VIEW TO DELETE")
  end

  if(!workspace_id.nil?)
    puts()
    puts("** DELETE THE WORKSPACE")
    puts(Workspace.find(:workspace_id => workspace_id).delete().inspect())
  else
    puts("** NO WORKSPACE TO DELETE")
  end

  if(!binary_id.nil?)
    puts()
    puts("** DELETE THE BINARY")
    puts(Binary.find(:binary_id => binary_id).delete().inspect())
  else
    puts("** NO BINARY TO DELETE")
  end
end
