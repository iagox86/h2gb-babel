$LOAD_PATH << File.dirname(__FILE__)

HOST = ARGV[0] || "http://localhost:9292"

require 'models/binary'
require 'models/view'
require 'models/workspace'

require 'pp' # TODO: Debug

binary_id    = nil
workspace_id = nil
view_id      = nil

@@pass = 0
@@fail = 0

def assert(boolean, test, pass = nil, fail = nil)
  if(boolean)
    @@pass += 1

    puts(" ++ PASSED: #{test} #{pass ? " (#{pass})" : ""}")

    return true
  else
    @@fail += 1

    puts(" -- FAILED: #{test} #{fail ? " (#{fail})" : ""}")

    return false
  end
end

def assert_equal(received, expected, description)
  return assert(expected === received, description, "VALUE: #{received}", "EXPECTED: #{expected}, RECEIVED: #{received}")
end

def assert_nil(value, description)
  return assert(value.nil?, description, nil, "EXPECTED: nil, RECEIVED: #{value}")
end

def assert_not_nil(value, description)
  return assert(!value.nil?, description, nil, "EXPECTED: (anything), RECEIVED: nil")
end

def assert_type(value, expected_class, description)
  return assert(value.is_a?(expected_class), description, nil, "EXPECTED: #{expected_class}, RECEIVED: #{value.class}")
end

@@revision = 0
def assert_revision(value, description)
  result = assert(value >= @@revision, description, nil, "EXPECTED: at least #{@@revision}, RECEIVED: #{value}")
  @@revision = value

  return result
end

def assert_array(received, expected, description)
  if(assert_type(received, Array, "#{description}: verifying it's an Array"))
    if(assert_equal(received.length(), expected.length(), "#{description}: Checking array length"))
      0.upto(expected.length() - 1) do |i|
        r = received[i]
        e = expected[i]

        if(e.is_a?(Array))
          assert_array(r, e, "#{description}[#{i}]")
        elsif(e.is_a?(Hash))
          assert_hash(r, e, "#{description}[#{i}]")
        else
          assert_equal(r, e, "#{description}[#{i}]")
        end
      end
    end
  end
end

def assert_hash(received, expected, description)
  if(assert_type(received, Hash, "#{description}: verifying it's a Hash"))
    expected.each_key do |k|
      if(expected[k].is_a?(Hash))
        assert_hash(received[k], expected[k], "#{description}[#{k}]")
      elsif(expected[k].is_a?(Array))
        assert_array(received[k], expected[k], "#{description}[#{k}]")
      else
        assert_equal(received[k], expected[k], "#{description}[#{k}]")
      end
    end
  end
end

def print_stats()
  total = @@pass + @@fail

  puts("Tests passed: %d / %d (%.2f%%)" % [@@pass, total, 100 * @@pass/total.to_f])
  puts("Tests failed: %d / %d (%.2f%%)" % [@@fail, total, 100 * @@fail/total.to_f])
end

def title(msg)
  puts()
  puts("** #{msg.upcase()} **")
end

begin
  ######## BINARY
  title("Testing binary creation")

  binary = Binary.create(
    :name => "Binary Test",
    :comment => "Test binary",
    :data => "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  )

  assert_not_nil(binary, "Checking if the binary was created")
  assert_not_nil(binary.o, "Checking if the binary was returned")
  assert_type(binary.o, Hash, "Checking if the binary was returned as a hash")
  assert_type(binary.o[:binary_id], Fixnum, "Checking if the binary's id is numeric")
  assert_equal(binary.o[:name], "Binary Test", "Checking if the binary's name is right")
  assert_equal(binary.o[:comment], "Test binary", "Checking if the binary's comment is correct")
  assert_nil(binary.o[:data], "Checking that the binary's data wasn't returned")

  binary_id = binary.o[:binary_id]

  title("Testing retrieving all binaries (with data)")
  all_binaries = Binary.all(:with_data => true)
  good = false
  all_binaries.o[:binaries].each do |b|
    if(b[:binary_id] == binary_id)
      good = true

      assert(true, "Checking if our binary is present")
      assert_equal(b[:name], "Binary Test", "Checking if the binary's name is right")
      assert_equal(b[:comment], "Test binary", "Checking if the binary's comment is correct")
      assert_equal(b[:data], "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "Checking if the binary's data is correct")
    end
  end
  assert(good, "Checking if our binary is present")

  title("Testing retrieving all binaries (without data)")
  all_binaries = Binary.all(:with_data => false)
  good = false
  all_binaries.o[:binaries].each do |b|
    if(b[:binary_id] == binary_id)
      good = true

      assert(true, "Checking if our binary is present")
      assert_equal(b[:name], "Binary Test", "Checking if the binary's name is right")
      assert_equal(b[:comment], "Test binary", "Checking if the binary's comment is correct")
      assert_nil(b[:data], "Checking if the binary's data is correctly skipped")
    end
  end
  assert(good, "Checking if our binary is present")

  title("Testing searching for a binary (no data)")
  binary_again = Binary.find(binary_id)

  assert_not_nil(binary_again, "The binary is successfully found")
  assert_not_nil(binary_again.o, "The binary's object is returned")
  assert_type(binary_again.o, Hash, "The binary's object is a hash")
  assert_equal(binary_again.o[:binary_id],binary.o[:binary_id], "The binary's id value matches the original binary's")
  assert_equal(binary_again.o[:name],     binary.o[:name], "The binary's name maches the original binary's")
  assert_equal(binary_again.o[:comment],  binary.o[:comment], "The binary's comment maches the original binary's")
  assert_nil(binary_again.o[:data], "Checking that no data was returned when it wasn't requested")

  title("Testing searching for a binary (with data)")
  binary_again = Binary.find(binary_id, :with_data => true)

  assert_not_nil(binary_again, "The binary is successfully found")
  assert_not_nil(binary_again.o, "The binary's object is returned")
  assert_type(binary_again.o, Hash, "The binary's object is a hash")
  assert_equal(binary_again.o[:binary_id],binary.o[:binary_id], "The binary's id value matches the original binary's")
  assert_equal(binary_again.o[:name],     binary.o[:name], "The binary's name maches the original binary's")
  assert_equal(binary_again.o[:comment],  binary.o[:comment], "The binary's comment maches the original binary's")
  assert_equal(binary_again.o[:data], "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "Checking if the binary's data is correct")

  title("Testing saving the binary")
  binary.o[:name] = "new binary name"
  binary.o[:comment] = "updated comment"
  saved = binary.save()

  assert_not_nil(saved, "A binary is successfully saved")
  assert_not_nil(saved.o, "The binary's object is returned")
  assert_type(saved.o, Hash, "The binary's object is a hash")
  assert_equal(saved.o[:binary_id],binary.o[:binary_id], "The binary's id value matches the original binary's")
  assert_equal(saved.o[:name],     "new binary name", "The binary's name was properly updated")
  assert_equal(saved.o[:comment],  "updated comment", "The binary's comment was properly updated")
  assert_equal(saved.o[:data],     binary.o[:data], "The binary's data maches the original binary's")

  title("Verifying the update by re-fetching the record")

  loaded = Binary.find(binary_id)
  assert_not_nil(loaded, "A binary is successfully saved")
  assert_not_nil(loaded.o, "The binary's object is returned")
  assert_type(loaded.o, Hash, "The binary's object is a hash")
  assert_equal(loaded.o[:binary_id],binary.o[:binary_id], "The binary's id value matches the original binary's")
  assert_equal(loaded.o[:name],     "new binary name", "The binary's name was properly updated")
  assert_equal(loaded.o[:comment],  "updated comment", "The binary's comment was properly updated")
  assert_equal(loaded.o[:data],     binary.o[:data], "The binary's data maches the original binary's")

  ######## WORKSPACE

  title("Create a workspace")
  workspace = Workspace.create(
    :binary_id => binary_id,
    :name => "test workspace"
  )

  assert_not_nil(workspace, "A workspace is successfully created")
  assert_not_nil(workspace.o, "The workspace's object is returned")
  assert_type(workspace.o, Hash, "The workspace's object is a hash")
  assert_type(workspace.o[:workspace_id], Fixnum, "The workspace's id value is present and numeric")
  assert_equal(workspace.o[:name], "test workspace", "The workspace's name is right")

  workspace_id = workspace.o[:workspace_id]

  title("Testing retrieving all workspaces")
  all_workspaces = Workspace.all(:binary_id => binary_id)

  good = false
  assert_equal(all_workspaces.o[:workspaces].length(), 1, "Making sure the new binary only has one workspace")
  assert_equal(all_workspaces.o[:workspaces][0][:workspace_id], workspace_id, "Making sure the id of the retrieved workspace is right")
  assert_equal(all_workspaces.o[:workspaces][0][:binary_id], binary_id, "Making sure the workspace belongs to the correct binary")

  title("Finding the workspace")
  new_workspace = Workspace.find(workspace_id)
  assert_not_nil(new_workspace, "A workspace is successfully found")
  assert_not_nil(new_workspace.o, "The workspace's object is returned")
  assert_type(new_workspace.o, Hash, "The workspace's object is a hash")
  assert_equal(new_workspace.o[:workspace_id], workspace_id, "The workspace's id matches the created workspace")
  assert_equal(new_workspace.o[:name], workspace.o[:name], "The workspace's name matches the created workspace")

  title("Updating the workspace")

  workspace.o[:name] = 'new name!?'
  updated = workspace.save()

  assert_not_nil(updated, "A workspace is successfully updated")
  assert_not_nil(updated.o, "The workspace's object is returned")
  assert_type(updated.o, Hash, "The workspace's object is a hash")
  assert_equal(updated.o[:workspace_id], workspace_id, "The workspace's id matches the created workspace")
  assert_equal(updated.o[:name], workspace.o[:name], "The workspace's name was updated properly")

  title("Doing another search for the updated workspace, just to be sure")

  updated = Workspace.find(workspace_id)

  assert_not_nil(updated, "A workspace is successfully updated")
  assert_not_nil(updated.o, "The workspace's object is returned")
  assert_type(updated.o, Hash, "The workspace's object is a hash")
  assert_equal(updated.o[:workspace_id], workspace_id, "The workspace's id matches the created workspace")
  assert_equal(updated.o[:name], workspace.o[:name], "The workspace's name was updated properly")

  ######## VIEW

  # Some constants
  NODE0 = {
    :type => "dword0",
    :value => "db 41414141 [I'm at 0x00000000]"
  }
  NODE4 = {
    :type => "dword4",
    :value => "db 42424242 [I'm at 0x00000004]"
  }
  NODE2 = {
    :type => "dword2",
    :value => "db 43434343 [I'm at 0x00000002]"
  }

  title("Create a view")
  view = View.create(
    :workspace_id => workspace_id,
    :name => "test view"
  )

  assert_not_nil(view, "A view is successfully created")
  assert_not_nil(view.o, "The view's object is returned")
  assert_type(view.o, Hash, "The view's object is a hash")
  assert_type(view.o[:view_id], Fixnum, "The view's id value is present and numeric")
  assert_equal(view.o[:name], "test view", "The view's name is right")
  assert_nil(view.o[:segments], "No segments were returned")
  assert_revision(view.o[:revision], "The first revision")

  view_id = view.o[:view_id]

  title("Testing retrieving all views")
  all_views = View.all(:workspace_id => workspace_id)

  good = false
  assert_equal(all_views.o[:views].length(), 1, "Making sure the new workspace only has one view")
  assert_equal(all_views.o[:views][0][:view_id], view_id, "Making sure the id of the retrieved view is right")
  assert_equal(all_views.o[:views][0][:workspace_id], workspace_id, "Making sure the view belongs to the correct workspace")
  assert_equal(all_views.o[:views][0][:revision], 1, "The revision hasn't changed")

  title("Finding the view")
  new_view = View.find(view_id)
  assert_not_nil(new_view, "A view is successfully found")
  assert_not_nil(new_view.o, "The view's object is returned")
  assert_type(new_view.o, Hash, "The view's object is a hash")
  assert_equal(new_view.o[:view_id], view_id, "The view's id matches the created view")
  assert_equal(new_view.o[:name], view.o[:name], "The view's name matches the created view")
  assert_nil(new_view.o[:segments], "No segments were returned")

  title("Updating the view")

  view.o[:name] = 'new name!?'
  updated = view.save()

  assert_not_nil(updated, "A view is successfully updated")
  assert_not_nil(updated.o, "The view's object is returned")
  assert_type(updated.o, Hash, "The view's object is a hash")
  assert_equal(updated.o[:view_id], view_id, "The view's id matches the created view")
  assert_equal(updated.o[:name], view.o[:name], "The view's name was updated properly")
  assert_nil(updated.o[:segments], "No segments were returned")

  title("Doing another search for the updated view, just to be sure")

  updated = View.find(view_id)

  assert_not_nil(updated, "A view is successfully updated")
  assert_not_nil(updated.o, "The view's object is returned")
  assert_type(updated.o, Hash, "The view's object is a hash")
  assert_equal(updated.o[:view_id], view_id, "The view's id matches the created view")
  assert_equal(updated.o[:name], view.o[:name], "The view's name was updated properly")
  assert_nil(updated.o[:segments], "No segments were returned")

  title("Create segment")
  segments = view.new_segment('s1', 0x00000000, 0x00004000, "AAAAAAAA")
  assert_type(segments, Hash, "The segment was created")
  assert_equal(segments.keys.length(), 1, "Only one segment was returned")
  segment = segments['s1']
  assert_type(segment, Hash, "The segment was created")
  assert_revision(segment[:revision], "The revision is increasing")
  assert_nil(segment[:nodes], "Segment isn't returning any nodes")
  assert_nil(segment[:data], "Segment isn't returning any data")

  title("Verifying the undo log")
  assert_hash(view.get_undo_log, {
    :undo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [ :name => 's1' ] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 's1' },
      },
    ],
    :redo => [
    ],
  }, "Checking the undo/redo logs after creating the new segment")

  title("Find segments (w/ default)")
  segments = view.get_segments('s1')
  assert_type(segments, Hash, "The segment was found")
  assert_equal(segments.keys.length(), 1, "Only one segment was returned")
  segment = segments['s1']
  assert_type(segment, Hash, "The segment was found")
  assert_revision(segment[:revision], "The revision is increasing")
  assert_nil(segment[:nodes], "Segment isn't returning any nodes")
  assert_nil(segment[:data], "Segment isn't returning any data")

  title("Find segments (without data, without nodes)")
  segments = view.get_segments('s1', :with_data => false, :with_nodes => false)
  assert_type(segments, Hash, "The segment was found")
  assert_equal(segments.keys.length(), 1, "Only one segment was returned")
  segment = segments['s1']
  assert_type(segment, Hash, "The segment was found")
  assert_revision(segment[:revision], "The revision is increasing")
  assert_nil(segment[:data], "Segment isn't returning any data")
  assert_nil(segment[:nodes], "Segment isn't returning any nodes")

  title("Find segments (without data, with nodes)")
  segments = view.get_segments('s1', :with_data => false, :with_nodes => true)
  assert_type(segments, Hash, "The segment was found")
  assert_equal(segments.keys.length(), 1, "Only one segment was returned")
  segment = segments['s1']
  assert_type(segment, Hash, "The segment was found")
  assert_revision(segment[:revision], "The revision is increasing")
  assert_nil(segment[:data], "Segment isn't returning any data")
  assert_type(segment[:nodes], Hash, "Nodes are returned as a hash")

  title("Find segments (with data, without nodes")
  segments = view.get_segments('s1', :with_data => true, :with_nodes => false)
  assert_type(segments, Hash, "The segment was found")
  assert_equal(segments.keys.length(), 1, "Only one segment was returned")
  segment = segments['s1']
  assert_type(segment, Hash, "The segment was found")
  assert_revision(segment[:revision], "The revision is increasing")
  assert_type(segment[:data], String, "Data is returned as a string")
  assert_equal(segment[:data], "AAAAAAAA", "Checking the data returned")
  assert_nil(segment[:nodes], "Segment isn't returning any nodes")

  title("Find segments (with data, with nodes")
  segments = view.get_segments('s1', :with_data => true, :with_nodes => true)
  assert_type(segments, Hash, "The segment was found")
  assert_equal(segments.keys.length(), 1, "Only one segment was returned")
  segment = segments['s1']
  assert_type(segment, Hash, "The segment was found")
  assert_revision(segment[:revision], "The revision is increasing")
  assert_type(segment[:data], String, "Data is returned as a string")
  assert_equal(segment[:data], "AAAAAAAA", "Checking the data returned")
  assert_type(segment[:nodes], Hash, "Nodes are returned as a hash")

  title("Find segments (without segments, because YOLO)")
  segments = view.get_segments('s1', :with_segments => false, :with_data => false, :with_nodes => false)
  assert_nil(segments, "No segments were returned")

  title("Find all segments")
  segments = view.get_segments()
  assert_equal(view.get_segments().length(), 1, "Checking if getting all segments returns exactly one segment")

  title("Deleting the segment")
  view.delete_segment('s1')
  assert_equal(view.get_segments().length(), 0, "Checking if the segment was deleted")

  title("Verifying the undo log")
  assert_hash(view.get_undo_log, {
    :undo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 's1' },
      },
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'delete_segments', :params => 's1' },
        :backward => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
      },
    ],
    :redo => [
    ],
  }, "Checking the undo/redo logs after creating the new segment")

  title("Testing undo (should restore the deleted segment)")
  segments = view.undo(:with_data => true, :with_nodes => true)
  assert_equal(segments.length(), 1, "Checking if the segment was restored")
  assert_type(segments, Hash, "The segment was found")
  assert_equal(segments.keys.length(), 1, "Only one segment was returned")
  segment = segments['s1']
  assert_type(segment, Hash, "The segment was found")
  assert_revision(segment[:revision], "The revision is increasing")
  assert_type(segment[:data], String, "Data is returned as a string")
  assert_equal(segment[:data], "AAAAAAAA", "Checking the data returned")
  assert_type(segment[:nodes], Hash, "Nodes are returned as a hash")

  title("Verifying the undo log")
  assert_hash(view.get_undo_log, {
    :undo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 's1' },
      },
    ],
    :redo => [
      {
        :type => 'checkpoint'
      },
      {
        :type      => 'method',
        :forward   => { :type => 'method', :method => 'delete_segments', :params => 's1' },
        :backward  => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
      },
    ],
  }, "Checking the undo/redo logs after creating the new segment")

  title("Double-checking undo")
  segments = view.get_segments('s1', :with_data => true, :with_nodes => true)
  assert_type(segments, Hash, "The segment was found")
  assert_equal(segments.keys.length(), 1, "Only one segment was returned")
  segment = segments['s1']
  assert_type(segment, Hash, "The segment was found")
  assert_revision(segment[:revision], "The revision is increasing")
  assert_type(segment[:data], String, "Data is returned as a string")
  assert_equal(segment[:data], "AAAAAAAA", "Checking the data returned")
  assert_type(segment[:nodes], Hash, "Nodes are returned as a hash")

  title("Testing a second undo (should undo the segment's initial creation)")
  segments = view.undo(:with_data => true, :with_nodes => true)
  assert_type(segments, Hash, "Checking if redo returned properly")
  assert_equal(segments.keys.length(), 0, "Checking if redo successfully deleted the segment")

  assert_hash(view.get_undo_log, {
    :undo => [ ],
    :redo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward   => { :type => 'method', :method => 'delete_segments', :params => 's1' },
        :backward  => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
      },
      {
        :type => 'checkpoint'
      },
      {
        :type      => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 's1' },
      },
    ],
  }, "Checking the undo/redo logs after creating the new segment")

  title("Testing redo (should restore the segment)")
  segments = view.redo(:with_data => true, :with_nodes => true)
  assert_equal(segments.length(), 1, "Checking if the segment was restored")
  assert_type(segments, Hash, "The segment was found")
  assert_equal(segments.keys.length(), 1, "Only one segment was returned")
  segment = segments['s1']
  assert_type(segment, Hash, "The segment was found")
  assert_revision(segment[:revision], "The revision is increasing")
  assert_type(segment[:data], String, "Data is returned as a string")
  assert_equal(segment[:data], "AAAAAAAA", "Checking the data returned")
  assert_type(segment[:nodes], Hash, "Nodes are returned as a hash")

  assert_hash(view.get_undo_log, {
    :undo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 's1' },
      },
    ],
    :redo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'delete_segments', :params => 's1' },
        :backward => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
      },
    ],
  }, "Checking the undo/redo logs after re-doing the creation of the first segment")

  title("Double-checking redo")
  segments = view.get_segments('s1', :with_data => true, :with_nodes => true)
  assert_type(segments, Hash, "The segment was found")
  assert_equal(segments.keys.length(), 1, "Only one segment was returned")
  segment = segments['s1']
  assert_type(segment, Hash, "The segment was found")
  assert_revision(segment[:revision], "The revision is increasing")
  assert_type(segment[:data], String, "Data is returned as a string")
  assert_equal(segment[:data], "AAAAAAAA", "Checking the data returned")
  assert_type(segment[:nodes], Hash, "Nodes are returned as a hash")

  title("Creating a segment to hopefully kill the redo buffer")
  new_view = view.new_segment("deleteme", 0x00000000, 0x00004000, "ABCDEFGH")
  segments = view.get_segments()
  assert_equal(segments.length, 2, "Making sure there are now 2 segments")

  assert_hash(view.get_undo_log, {
    :undo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 's1' },
      },
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{ :name => 'deleteme' }] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 'deleteme' },
      },
    ],
    :redo => [ ],
  }, "Checking the undo/redo logs after killing the redo buffer")

  title("Attempting a redo, which should fail")
  view.redo()
  segments = view.get_segments()
  assert_equal(segments.length, 2, "Making sure there are still 2 segments")
  assert_not_nil(segments['s1'], "The first segment is still present")
  assert_not_nil(segments['deleteme'], "The new segment is still present")

  assert_hash(view.get_undo_log, {
    :undo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 's1' },
      },
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{ :name => 'deleteme' }] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 'deleteme' },
      },
    ],
    :redo => [ ],
  }, "Checking the undo/redo logs after killing the redo buffer")

  title("Attempting another undo, which should delete the new segment")
  view.undo()
  segments = view.get_segments()
  assert_equal(segments.length, 1, "Making sure there are still 2 segments")
  assert_not_nil(segments['s1'], "The first segment is still present")
  assert_nil(segments['deleteme'], "The new segment is gone")

  assert_hash(view.get_undo_log, {
    :undo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 's1' },
      },
    ],
    :redo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{ :name => 'deleteme' }] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 'deleteme' },
      },
    ],
  }, "Checking the undo/redo logs after undoing the new segment")

  title("Attempting a redo, which should restore the new segment")
  view.redo()
  segments = view.get_segments()
  assert_equal(segments.length, 2, "Making sure there are still 2 segments")
  assert_not_nil(segments['s1'], "The first segment is still present")
  assert_not_nil(segments['deleteme'], "The new segment is back")

  assert_hash(view.get_undo_log, {
    :undo => [
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{:name => 's1'}] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 's1' },
      },
      {
        :type => 'checkpoint'
      },
      {
        :type     => 'method',
        :forward  => { :type => 'method', :method => 'create_segments', :params => [{ :name => 'deleteme' }] },
        :backward => { :type => 'method', :method => 'delete_segments', :params => 'deleteme' },
      },
    ],
    :redo => [
    ],
  }, "Checking the undo/redo logs after re-doing the new segment")

  title("Attempting another undo, which should delete the new segment *AGAIN*")
  view.undo()
  segments = view.get_segments()
  assert_equal(segments.length, 1, "Making sure we're back to one segment")
  assert_not_nil(segments['s1'], "The first segment is still present")
  assert_nil(segments['deleteme'], "The new segment is gone")

  title("Attempting a final undo, which should bring us back to the original state")
  view.undo()
  segments = view.get_segments()
  assert_equal(segments.length, 0, "Making sure there are still 2 segments")
  assert_nil(segments['s1'], "The first segment is gone")
  assert_nil(segments['deleteme'], "The new segment is gone")

  title("Creating a brand new segment to test nodes in")
  segment = view.new_segment('s2', 0x00000000, 0x00004000, "ABCDEFGH")
  assert_equal(segment.keys.length(), 1, "Checking if only the new segment exists")
  assert_not_nil(segment['s2'], "Checking that the segment was created")

  title("Finding the segment")
  segment = view.get_segment('s2', :with_nodes => true, :with_data => true)
  assert_type(segment, Hash, "Checking if the segment was returned")
  assert_type(segment[:nodes], Hash, "Checking if nodes are present")
  assert_equal(segment[:nodes].length, 8, "Verifying that 8 nodes were returned")
  assert_equal(segment[:nodes][0x00000000][:type], 'undefined', "Verifying that the nodes are all undefined")
  assert_equal(segment[:nodes][0x00000001][:type], 'undefined', "Verifying that the nodes are all undefined")
  assert_equal(segment[:nodes][0x00000002][:type], 'undefined', "Verifying that the nodes are all undefined")
  assert_equal(segment[:nodes][0x00000003][:type], 'undefined', "Verifying that the nodes are all undefined")
  assert_equal(segment[:nodes][0x00000004][:type], 'undefined', "Verifying that the nodes are all undefined")
  assert_equal(segment[:nodes][0x00000005][:type], 'undefined', "Verifying that the nodes are all undefined")
  assert_equal(segment[:nodes][0x00000006][:type], 'undefined', "Verifying that the nodes are all undefined")
  assert_equal(segment[:nodes][0x00000007][:type], 'undefined', "Verifying that the nodes are all undefined")

  title("Creating a 32-bit node")
  result = view.new_node('s2', 0x00000000, NODE0[:type], 4, NODE0[:value], { :test => '123', :test2 => 456 }, [0x00000004])
  assert_type(result, Hash, "Checking if the new_node function returned properly")
  assert_equal(result.keys.length, 1, "Verifying that only one segment was returned")
  segment = result['s2']
  assert_type(segment, Hash, "Checking if the segment was formatted properly")
  assert_equal(segment[:nodes].length(), 2, "Verifying that two nodes were returned (the node with the new xref and the original node)")

  title("Making sure there are exactly 5 nodes present")
  segment = view.get_segment('s2', :with_nodes => true, :with_data => true)
  assert_type(segment, Hash, "Checking if the segment was returned")
  assert_equal(segment[:nodes].length(), 5, "Checking if the correct number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => NODE0,
    0x00000004 => { :type => 'undefined', :xrefs => [0x00000000] },
    0x00000005 => { :type => 'undefined' },
    0x00000006 => { :type => 'undefined' },
    0x00000007 => { :type => 'undefined' },
  }, "Checking if the five nodes were properly returned")

  title("Creating a non-overlapping 32-bit node")
  result = view.new_node('s2', 0x00000004, NODE4[:type], 4, NODE4[:value], { :test => 321, :test2 => '654' }, [0x00000000])

  assert_type(result, Hash, "Checking if the new_node function returned properly")
  assert_equal(result.keys.length, 1, "Verifying that one segment was returned")
  segment = result['s2']
  assert_equal(segment[:nodes].length(), 2, "Checking if the correct number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => NODE0.merge({:xrefs => [0x00000004]}),
    0x00000004 => NODE4.merge({:xrefs => [0x00000000]}),
  }, "Checking if the nodes were properly returned")

  title("Making sure both nodes are in good shape")
  segment = view.get_segment('s2', :with_nodes => true, :with_data => true)
  assert_type(segment, Hash, "Checking if the segment was returned")
  assert_equal(segment[:nodes].length(), 2, "Checking if the correct number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => NODE0.merge({:xrefs => [0x00000004]}),
    0x00000004 => NODE4.merge({:xrefs => [0x00000000]}),
  }, "Checking if the nodes were properly returned")

  title("Creating an overlapping 32-bit node")
  result = view.new_node('s2', 0x00000002, NODE2[:type], 4, NODE2[:value], { :test => 321, :test2 => '654' }, [])
  segment = result['s2']
  assert_equal(segment[:nodes].length(), 5, "Checking if the correct number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => { :type => 'undefined' },
    0x00000001 => { :type => 'undefined' },
    0x00000002 => NODE2,
    0x00000006 => { :type => 'undefined' },
    0x00000007 => { :type => 'undefined' },
  }, "Checking if the nodes were properly returned")

  title("Making sure it's still in good shape")
  segment = view.get_segment('s2', :with_nodes => true, :with_data => true)
  assert_type(segment, Hash, "Checking if the segment was returned")
  assert_type(segment[:nodes], Hash, "Checking if nodes are present")
  assert_equal(segment[:nodes].length(), 5, "Checking if the correct number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => { :type => 'undefined' },
    0x00000001 => { :type => 'undefined' },
    0x00000002 => NODE2,
    0x00000006 => { :type => 'undefined' },
    0x00000007 => { :type => 'undefined' },
  }, "Checking if the nodes were properly returned")

  title("Undoing the third node")
  result = view.undo(:with_nodes => true)
  segment = result['s2']
  assert_equal(segment[:nodes].length(), 2, "Checking if the correct number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => NODE0.merge({:xrefs => [0x00000004]}),
    0x00000004 => NODE4.merge({:xrefs => [0x00000000]}),
  }, "Checking if the nodes were properly returned")

  title("Undoing the second node")
  result = view.undo(:with_nodes => true)

  segment = result['s2']
  assert_equal(segment[:nodes].length(), 5, "Checking that the right number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => NODE0.merge({:xrefs => nil}),
    0x00000004 => { :type => 'undefined', :xrefs => [0x00000000] },
    0x00000005 => { :type => 'undefined' },
    0x00000006 => { :type => 'undefined' },
    0x00000007 => { :type => 'undefined' },
  }, "Checking if the nodes were properly returned")

  segment = view.get_segment('s2', :with_nodes => true)
  assert_equal(segment[:nodes].length(), 5, "Checking that the right number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => NODE0,
    0x00000004 => { :type => 'undefined', :xrefs => [0x00000000] },
    0x00000005 => { :type => 'undefined' },
    0x00000006 => { :type => 'undefined' },
    0x00000007 => { :type => 'undefined' },
  }, "Checking if the nodes were properly returned")

  title("Undoing the first node")
  result = view.undo(:with_nodes => true)
  segment = result['s2']
  assert_equal(segment[:nodes].length(), 5, "Checking that the right number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => { :type => 'undefined' },
    0x00000001 => { :type => 'undefined' },
    0x00000002 => { :type => 'undefined' },
    0x00000003 => { :type => 'undefined' },
    0x00000004 => { :type => 'undefined' },
  }, "Checking if the nodes were properly returned")

  segment = view.get_segment('s2', :with_nodes => true)
  assert_equal(segment[:nodes].length(), 8, "Checking that the right number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => { :type => 'undefined' },
    0x00000001 => { :type => 'undefined' },
    0x00000002 => { :type => 'undefined' },
    0x00000003 => { :type => 'undefined' },
    0x00000004 => { :type => 'undefined' },
    0x00000005 => { :type => 'undefined' },
    0x00000006 => { :type => 'undefined' },
    0x00000007 => { :type => 'undefined' },
  }, "Checking if the nodes were properly returned")

  title("Redo: creating the first 32-bit node")
  result = view.redo(:with_nodes => true)
  assert_type(result, Hash, "Checking if the new_node function returned properly")
  assert_equal(result.keys.length, 1, "Verifying that only one segment was returned")
  segment = result['s2']
  assert_equal(segment[:nodes].length(), 2, "Verifying that two nodes were returned (the node with the new xref and the original node)")
  assert_hash(segment[:nodes], {
    0x00000000 => NODE0,
    0x00000004 => { :type => 'undefined', :xrefs => [0x00000000] },
  }, "Checking if the nodes were properly returned")

  title("Making sure there are exactly 5 nodes present")
  segment = view.get_segment('s2', :with_nodes => true, :with_data => true)
  assert_type(segment, Hash, "Checking if the segment was returned")
  assert_equal(segment[:nodes].length(), 5, "Checking that the right number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => NODE0,
    0x00000004 => { :type => 'undefined', :xrefs => [0x00000000] },
    0x00000005 => { :type => 'undefined' },
    0x00000006 => { :type => 'undefined' },
    0x00000007 => { :type => 'undefined' },
  }, "Checking if the nodes were properly returned")

  title("Redo: creating a non-overlapping 32-bit node")
  result = view.redo(:with_data => true)

  assert_type(result, Hash, "Checking if the new_node function returned properly")
  assert_equal(result.keys.length, 1, "Verifying that one segment was returned")
  segment = result['s2']
  assert_equal(segment[:nodes].length(), 2, "Checking that the right number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => NODE0.merge({:xrefs => [0x00000004]}),
    0x00000004 => NODE4.merge({:xrefs => [0x00000000]}),
  }, "Checking if the nodes were properly returned")

  title("Making sure both nodes are in good shape")
  segment = view.get_segment('s2', :with_nodes => true, :with_data => true)
  assert_equal(segment[:nodes].length(), 2, "Checking that the right number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => NODE0.merge({:xrefs => [0x00000004]}),
    0x00000004 => NODE4.merge({:xrefs => [0x00000000]}),
  }, "Checking if the nodes were properly returned")

  title("Redo: creating an overlapping 32-bit node")
  result = view.redo(:with_data => true)
  segment = result['s2']
  assert_equal(segment[:nodes].length(), 5, "Checking that the right number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => { :type => 'undefined'},
    0x00000001 => { :type => 'undefined'},
    0x00000002 => NODE2,
    0x00000006 => { :type => 'undefined'},
    0x00000007 => { :type => 'undefined'},
  }, "Checking if the nodes were properly returned")

  title("Making sure it's still in good shape")
  segment = view.get_segment('s2', :with_nodes => true, :with_data => true)
  assert_equal(segment[:nodes].length(), 5, "Checking that the right number of nodes were returned")
  assert_hash(segment[:nodes], {
    0x00000000 => { :type => 'undefined'},
    0x00000001 => { :type => 'undefined'},
    0x00000002 => NODE2,
    0x00000006 => { :type => 'undefined'},
    0x00000007 => { :type => 'undefined'},
  }, "Checking if the nodes were properly returned")

  title("Creating 4 segments at once")
  result = view.new_segments({
    'A' => { :address => 0,  :file_address => 0, :data => 'A' * 16, },
    'B' => { :address => 16, :file_address => 1, :data => 'B' * 16, },
    'C' => { :address => 32, :file_address => 2, :data => 'C' * 16, },
    'D' => { :address => 48, :file_address => 3, :data => 'D' * 16, },
  })
  assert_equal(result.length, 4, "Checking that the right number of segments were returned")
  assert_hash(result, {
    'A' => { :address => 0,  :file_address => 0 },
    'B' => { :address => 16, :file_address => 1 },
    'C' => { :address => 32, :file_address => 2 },
    'D' => { :address => 48, :file_address => 3 },
  }, "Checking that the segments were created")

  result = view.undo()

  # Go back to a clean slate
  title("Creating 4 segments at once, and requesting data + nodes")
  result = view.new_segments({
    'A' => { :address => 0,  :file_address => 0, :data => 'A' * 16, },
    'B' => { :address => 16, :file_address => 1, :data => 'B' * 16, },
    'C' => { :address => 32, :file_address => 2, :data => 'C' * 16, },
    'D' => { :address => 48, :file_address => 3, :data => 'D' * 16, },
  }, :with_data => true, :with_nodes => true)

  assert_equal(result.length, 4, "Checking that the right number of segments were returned")
  assert_hash(result, {
    'A' => { :address => 0,  :file_address => 0, :data => 'A' * 16, :nodes => { 0  => {:type => 'undefined'}}, },
    'B' => { :address => 16, :file_address => 1, :data => 'B' * 16, :nodes => { 16 => {:type => 'undefined'}}, },
    'C' => { :address => 32, :file_address => 2, :data => 'C' * 16, :nodes => { 32 => {:type => 'undefined'}}, },
    'D' => { :address => 48, :file_address => 3, :data => 'D' * 16, :nodes => { 48 => {:type => 'undefined'}}, },
  }, "Checking that the segments were created")

  # Go back to a clean slate
  result = view.undo()

  title("Creating nodes using an array")
  segment = view.new_segment('A', 0x1000, 0x0000, "1111222233334444")
  result = view.new_nodes('A', [
    {:address => 0x1000, :type => 'defined', :length => 4, :value => 'AAAA', :refs => []},
    {:address => 0x1004, :type => 'defined', :length => 4, :value => 'BBBB', :refs => []},
    {:address => 0x1008, :type => 'defined', :length => 4, :value => 'CCCC', :refs => []},
    {:address => 0x100c, :type => 'defined', :length => 4, :value => 'DDDD', :refs => []},
  ])
  assert_hash(result, { 'A' => {
    :address => 0x1000,
    :nodes => {
      0x1000 => {:address => 0x1000, :type => 'defined', :length => 4, :value => 'AAAA', :refs => []},
      0x1004 => {:address => 0x1004, :type => 'defined', :length => 4, :value => 'BBBB', :refs => []},
      0x1008 => {:address => 0x1008, :type => 'defined', :length => 4, :value => 'CCCC', :refs => []},
      0x100c => {:address => 0x100c, :type => 'defined', :length => 4, :value => 'DDDD', :refs => []},
    }
  }}, "new_nodes")

  # Delete a node
  result = view.delete_nodes('A', [0x1008])
  assert_hash(result[:segments], { 'A' => {
    :address => 0x1000,
    :nodes => {
      0x1008 => {:address => 0x1008, :type => 'undefined', :length => 1},
      0x1009 => {:address => 0x1009, :type => 'undefined', :length => 1},
      0x100a => {:address => 0x100a, :type => 'undefined', :length => 1},
      0x100b => {:address => 0x100b, :type => 'undefined', :length => 1},
    }
  }}, 'deleted_nodes')

  # Get all nodes to make sure it's sane
  assert_hash(view.get_segment('A', :with_nodes => true), { :nodes =>
    {
      0x1000 => {:address => 0x1000, :type => 'defined', :length => 4, :value => 'AAAA', :raw => '1111', :refs => []},
      0x1004 => {:address => 0x1004, :type => 'defined', :length => 4, :value => 'BBBB', :raw => '2222', :refs => []},
      0x1008 => {:address => 0x1008, :type => 'undefined', :length => 1},
      0x1009 => {:address => 0x1009, :type => 'undefined', :length => 1},
      0x100a => {:address => 0x100a, :type => 'undefined', :length => 1},
      0x100b => {:address => 0x100b, :type => 'undefined', :length => 1},
      0x100c => {:address => 0x100c, :type => 'defined', :length => 4, :value => 'DDDD', :raw => '4444', :refs => []},
    }
  }, 'delete_nodes_again')

  # TODO: Create nodes using an array
  # TODO: Segments that don't start at address 0
  # TODO: More Xref stuff
  # TODO: Locking the revision and making sure the right stuff shows up
  # TODO: Apparently I'm not testing the case when 'undo' creates a new segment

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
      title("Deleting view")
      result = View.find(view_id).delete()
      assert_not_nil(result, "Checking if delete() returned")
      assert_type(result.o, Hash, "Checking if delete() returned a hash")
      assert_equal(result.o[:deleted], true, "Checking if delete() returned successfully")
    else
      puts("** NO VIEW TO DELETE")
    end
  rescue Exception => e
    puts("Delete failed: #{e}")
  end

  begin
    title("Deleting workspace")
    if(!workspace_id.nil?)
      result = Workspace.find(workspace_id).delete()
      assert_not_nil(result, "Checking if delete() returned")
      assert_type(result.o, Hash, "Checking if delete() returned a hash")
      assert_equal(result.o[:deleted], true, "Checking if delete() returned successfully")
    else
      puts("** NO WORKSPACE TO DELETE")
    end
  rescue Exception => e
    puts("Delete failed: #{e}")
  end

  begin
    title("Deleting binary")
    if(!binary_id.nil?)
      result = Binary.find(binary_id).delete()
      assert_not_nil(result, "Checking if delete() returned")
      assert_type(result.o, Hash, "Checking if delete() returned a hash")
      assert_equal(result.o[:deleted], true, "Checking if delete() returned successfully")
    else
      puts("** NO BINARY TO DELETE")
    end
  rescue Exception => e
    puts("Delete failed: #{e}")
  end
end

print_stats()
