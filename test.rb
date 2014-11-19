$LOAD_PATH << File.dirname(__FILE__)

HOST = ARGV[0] || "http://localhost:9292"

require 'models/binary'
require 'models/view'
require 'models/workspace'

require 'pp' # TODO: Debug

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
  puts(binary.inspect)
  puts(binary.o.inspect)
  binary_id = binary.o[:binary_id]

  if(!binary_id)
    puts("A valid binary wasn't returned!")
    puts("We got: #{binary.inspect}")
    exit
  else
    puts("(success)")
  end
  puts(binary.inspect)
  puts("binary_id: %d" % binary_id)

  puts()
  puts("** GET ALL BINARIES (should include the new one)")
  all_binaries = Binary.all()
  good = false
  all_binaries.o[:binaries].each do |b|
    if(b[:binary_id] == binary_id)
      good = true
      puts("  * Found our new binary!")
    end
  end
  if(!good)
    puts("Couldn't find out new binary!")
    exit
  else
    puts("(success)")
  end

  puts()
  puts("** FIND A BINARY")
  binary_again = Binary.find(binary_id)
  puts(binary_again.inspect)
  binary = binary_again
  if(binary.o[:name] != "Binary Test")
    puts("Binary has the wrong name!")
    exit
  else
    puts("(success)")
  end

  puts()
  puts("** UPDATE A BINARY")
  binary.o[:name] = "new binary name"
  puts(binary.save().inspect)

  puts()
  puts("** VERIFY THE UPDATE")
  binary = Binary.find(binary_id)
  puts(binary.inspect)
  if(binary.o[:name] != "new binary name")
    puts("Binary update failed!")
    exit
  else
    puts("(success)")
  end

  # TODO: Inspect the body contents

  puts()
  puts("** CREATE A WORKSPACE")
  workspace = Workspace.create(:binary_id => binary_id, :name => "test workspace")
  puts(workspace.inspect)
  workspace_id = workspace.o[:workspace_id]

  if(!workspace_id)
    puts("A valid workspace wasn't returned!")
    puts("We got: #{workspace.inspect}")
    exit
  else
    puts("(success)")
  end
  puts("workspace_id: %d" % workspace_id)

  puts()
  puts("** LIST ALL WORKSPACES")
  workspaces = Workspace.all(:binary_id => binary_id)
  if(workspaces.o[:workspaces].length != 1)
    puts("We should have exactly one workspace under our new binary, but we have #{workspaces[:workspaces].length} instead!")
    exit
  else
    puts("(success)")
  end
  workspaces.o[:workspaces].each do |w|
    if(w[:workspace_id] != workspace_id)
      puts("The workspace returned by 'all' didn't have the same id as the new workspace!")
      exit
    else
      puts("(success)")
    end
    puts(w.inspect)
  end

  puts()
  puts("** FIND THE WORKSPACE")
  workspace = Workspace.find(workspace_id)
  puts(workspace.inspect)
  if(workspace.o[:name] != "test workspace")
    puts("Workspace created has the wrong name!")
    exit
  else
    puts("(success)")
  end

  puts()
  puts("** UPDATE THE WORKSPACE")
  workspace.o[:name] = "new workspace name"
  workspace.save()
  workspace = Workspace.find(workspace_id)
  if(workspace.o[:name] != "new workspace name")
    puts("Workspace update failed!")
    exit
  else
    puts("(success)")
  end
  puts(workspace.inspect)

  puts()
  puts("** CREATE VIEW")
  view = View.create(:workspace_id => workspace_id, :name => "view name")
  puts(view.inspect)
  view_id = view.o[:view_id]

  puts()
  puts("** LIST VIEWS")
  views = View.all(:workspace_id => workspace_id)
  puts(views.inspect)
  if(views.o[:views].length != 1)
    puts("Exactly 1 result wasn't returned as expected! Instead, #{views[:views].count} were returned")
  end
  views.o[:views].each do |v|
    if(v[:view_id] != view_id)
      puts("The view returned by 'all' didn't have the same id as the new view!")
      exit
    end
  end

  puts()
  puts("** FIND VIEW")
  view = View.find(view_id)
  puts(view.inspect)
  if(view.o[:name] != "view name")
    puts("The view's name was wrong!")
    exit
  end

  if(!view.o[:segments].nil?)
    puts("The view returned segments when it wasn't supposed to!")
    exit
  end

  puts()
  puts("** UPDATE THE VIEW")
  view.o[:name] = "new view name"
  view.save()
  view = View.find(view_id)
  if(view.o[:name] != "new view name")
    puts("view update failed!")
    exit
  end
  puts(view.inspect)

  puts()
  puts("** CREATE SEGMENT")
  segment = view.new_segment("s1", 0x00000000, 0x00004000, "AAAAAAAA")
  puts(segment.inspect)

  puts()
  puts("** FIND SEGMENT (without nodes + without data)")
  segments = view.get_segments("s1", :with_nodes => false, :with_data => false)
  puts(segments.inspect)
  if(segments.length() != 1)
    puts("It didn't return exactly one segment!")
    exit
  end
  segments.each do |s|
    if(!s[:nodes].nil?)
      pp s.nodes
      puts("The segment returned nodes that it wasn't supposed to!")
      exit
    end

    if(s[:data] != nil)
      puts("Data was returned when it shouldn't be!")
      puts()
      puts("Data: #{s[:data]}")
      exit
    end
  end

  puts()
  puts("** FIND SEGMENT (making sure defaults match)")
  segments = view.get_segments("s1")
  puts(segments.inspect)
  segments.each do |s|
    if(!s[:nodes].nil?)
      puts("The segment returned nodes that it wasn't supposed to!")
      exit
    end

    if(s[:data] != nil)
      puts("Data was returned when it shouldn't be!")
      puts()
      puts("Data: #{s[:data]}")
      exit
    end
  end
  if(segments.length() != 1)
    puts("It didn't return exactly one segment!")
    exit
  end

  puts()
  puts("** FIND SEGMENT (without nodes + with data)")
  segments = view.get_segments("s1", :with_nodes => false, :with_data => true)
  puts(segments.inspect)
  segments.each do |s|
    if(!s[:nodes].nil?)
      puts("The segment returned nodes that it wasn't supposed to!")
      exit
    end
  end
  if(segments.length() != 1)
    puts("It didn't return exactly one segment!")
    exit
  end

  puts()
  puts("** FIND SEGMENT (with everything)")
  segment = view.get_segment("s1", :with_nodes => true, :with_data => true)
  puts(segment.inspect)
  if(segment[:data] != "AAAAAAAA")
    puts("The segment had the wrong data!")
    exit
  end
  if(segment[:nodes].nil?)
    puts("It didn't return nodes, as requested!")
    exit
  end
  if(segment[:nodes].length() != 8)
    puts("It didn't return the right number of nodes! (expected 8, found #{segment[:nodes].length()})")
    exit
  end
  segment[:nodes].each do |n|
    if(n[:type] != 'undefined')
      puts("At least one node is the wrong type!")
      puts("Expected: 'undefined', found: '#{n[:type]}'")
      exit
    end
  end

  puts()
  puts("** FIND ALL SEGMENTS")
  segments = view.get_segments()
  puts(segments.inspect)
  if(segments.length != 1)
    puts("Wrong number of segments returned when fetching all segments!")
    exit
  end

  puts()
  puts("** DELETE SEGMENT")
  puts(view.delete_segment("s1").inspect())

  puts()
  puts("** CHECKING THE DELETE")
  segments = view.get_segments()
  puts(segments.inspect)
  if(segments.length != 0)
    puts("Segment didn't delete successfully!")
    exit
  end

  puts()
  puts("** TRYING TO UNDO THE DELETE")
  puts(view.undo())

  puts()
  puts("** CHECKING THE UNDO")
  segments = view.get_segments()
  puts(segments.inspect)
  if(segments.length != 1)
    puts("The undo didn't restore the segment like it should have!")
    exit
  end

#  puts()
#  puts("** TRYING TO REDO THE DELETE")
#  puts(view.redo())
#  puts()
#
#  puts("** CHECKING THE REDO")
#  segments = view.get_segments()
#  puts(segments.inspect)
#  if(segments.length != 0)
#    puts("The redo didn't delete the segment like it should have!")
#    exit
#  end
  # TODO: Use REDO for this instead once I fix REDO

  puts()
  puts("** DELETE SEGMENT")
  puts(view.delete_segment("s1").inspect())

  puts()
  puts("** CREATING A NEW SEGMENT")
  segment = view.new_segment("s2", 0x00000000, 0x00004000, "ABCDEFGH")
  puts(segment.inspect)

  puts()
  puts("** CREATING A 32-BIT NODE")
  result = view.new_node('s2', 0x00000000, "dword", 4, "db 41414141", { :test => '123', :test2 => 456 }, [0x00000004])
#  if(result[:segments][0][:nodes].length() != 5)
#    puts("The wrong number of 'changed nodes' were returned for the first node!")
#    puts(result.inspect)
#    exit
#  end
  puts()
  puts("(should be one defined node, 5 undefined):")
  view.print()

  puts()
  puts("** CREATING ANOTHER 32-BIT NODE")
  result = view.new_node('s2', 0x00000004, "dword", 4, "db 42424242", { :test => 321, :test2 => '654' }, [0x00000000])
  if(result[:segments][0][:nodes].length() != 1)
    puts("The wrong number of 'changed nodes' were returned for the second node!")
    puts(result.inspect)
    exit
  end
  puts()
  puts("2 (should be two defined nodes):")
  view.print()

  puts()
  puts("** CREATING AN OVERLAPPING 32-BIT NODE")
  result = view.new_node('s2', 0x00000002, "dword", 4, "db 43434343", { :test => 321, :test2 => '654' }, [0x00000000])
  if(result[:segments][0][:nodes].length() != 5)
    puts("The wrong number of 'changed nodes' were returned for the third node (expected 5, got #{result[:segments][0][:nodes].length()})!")
    pp(result)
    exit
  end
  puts()
  puts("3 (should be one defined node, with two undefined on either side):")
  view.print()

  puts()
  puts("** TRYING TO UNDO THE THIRD NODE (should have two defined nodes, 41414141 and 42424242)")
  puts(view.undo())
  view.print()

  puts()
  puts("** TRYING TO UNDO THE SECOND NODE (should have one defined node, 41414141)")
  puts(view.undo())
  view.print()

  puts()
  puts("** TRYING TO UNDO THE FIRST NODE (should have no defined nodes)")
  puts(view.undo())
  view.print()

  puts()
  puts("** TRYING TO REDO THE FIRST NODE")
  puts(view.redo())
  view.print()

  # TODO: This one is currently failing
  puts()
  puts("** TRYING TO REDO THE SECOND NODE")
  puts(view.redo())
  view.print()

  puts()
  puts("Everything is working!!!")
  puts()
  exit

  # TODO: Test undoing an action that makes multiple changes

  puts()
  puts("** CHECKING IF THEY WERE CREATED PROPERLY")
  segment = view.get_segment("s2", :with_nodes => true, :with_data => true)
  pp segment

  if(segment[:nodes].length() != 2)
    puts("The wrong number of nodes were returned")
    exit
  end
  node1 = segment[:nodes][0]
  if(node1[:type] != 'dword')
    puts("node1 was the wrong type!")
    exit
  end
  if(node1[:xrefs].length() != 1 || node1[:xrefs][0] != 4)
    puts("node1's xrefs were wrong!")
    exit
  end

  node2 = segment[:nodes][1]
  if(node2[:type] != 'dword')
    puts("node2 was the wrong type!")
    exit
  end
  if(node2[:xrefs].length() != 1 || node2[:xrefs][0] != 0)
    puts("node2's xrefs were wrong!")
    exit
  end

  puts("*** CREATING AN OVERLAPPING NODE")
  result = view.new_node(0x00000002, "dword", 4, "db 43434343", { }, [])
#  if(result[:segments][0][:nodes].length() != 5)
#    puts("The wrong number of 'changed nodes' were returned for the overlapping node!")
#    puts(result.inspect)
#    exit
#  end

  view.print()

  # TODO: Create nodes using an array

  puts("ALL DONE! EVERYTHING IS GOOD!!!")
rescue Exception => e
  puts()
  puts("EXCEPTION!!")
  puts(e)
  puts()
  puts(e.backtrace)

  puts("Press 'enter' to continue")
  gets()
ensure

  puts()
  puts("CLEANING UP")
  puts()

  begin
    if(!view_id.nil?)
      puts()
      puts("** DELETING VIEW")
      puts(View.find(view_id).delete().inspect())
    else
      puts("** NO VIEW TO DELETE")
    end
  rescue Exception => e
    puts("Delete failed: #{e}")
  end

  begin
    if(!workspace_id.nil?)
      puts()
      puts("** DELETE THE WORKSPACE")
      puts(Workspace.find(workspace_id).delete().inspect())
    else
      puts("** NO WORKSPACE TO DELETE")
    end
  rescue Exception => e
    puts("Delete failed: #{e}")
  end

  begin
    if(!binary_id.nil?)
      puts()
      puts("** DELETE THE BINARY")
      puts(Binary.find(binary_id).delete().inspect())
    else
      puts("** NO BINARY TO DELETE")
    end
  rescue Exception => e
    puts("Delete failed: #{e}")
  end
end
