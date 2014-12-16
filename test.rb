require 'models/binary'
require 'models/workspace'

require 'pp'

@@pass = 0
@@fail = 0

@@binary_id = nil
@@workspace_id = nil

# ASCII-8bit is used to represent a byte string
BINARY_TEST_DATA = IO.read(File.dirname(__FILE__) + "/testfiles/sample.raw").force_encoding(Encoding::ASCII_8BIT)

class Test
  def Test.assert(boolean, test, pass = nil, fail = nil)
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

  def Test.assert_equal(received, expected, description)
    return assert(expected === received, description, nil, "EXPECTED: #{expected}:#{expected.class}, RECEIVED: #{received}:#{received.class}")
  end

  def Test.assert_nil(value, description)
    return assert(value.nil?, description, nil, "EXPECTED: nil, RECEIVED: #{value}:#{value.class}")
  end

  def Test.assert_not_nil(value, description)
    return assert(!value.nil?, description, nil, "EXPECTED: (anything), RECEIVED: nil")
  end

  def Test.assert_type(value, expected_class, description)
    return assert(value.is_a?(expected_class), description, nil, "EXPECTED: #{expected_class}, RECEIVED: #{value.class}")
  end

  def Test.assert_array(received, expected, description)
    if(assert_type(received, Array, "Checking #{description}: verifying it's an Array"))
      if(assert_equal(received.length(), expected.length(), "Checking if #{description} has correct array length"))
        0.upto(expected.length() - 1) do |i|
          r = received[i]
          e = expected[i]

          if(e.is_a?(Array))
            assert_array(r, e, "#{description}[#{i}]")
          elsif(e.is_a?(Hash))
            assert_hash(r, e, "#{description}[#{i}]")
          else
            assert_equal(r, e, "Checking #{description}[#{i}]")
          end
        end
      end
    end
  end

  def Test.assert_hash(received, expected, description, check_length = false)
    if(assert_type(received, Hash, "Checking #{description}: verifying it's a Hash"))
      if(check_length)
        assert_equal(received.length, expected.length, "Checking #{description}.length()")
      end

      expected.each_key do |k|
        if(expected[k].is_a?(Hash))
          assert_hash(received[k], expected[k], "#{description}[#{k}]")
        elsif(expected[k].is_a?(Array))
          assert_array(received[k], expected[k], "#{description}[#{k}]")
        else
          assert_equal(received[k], expected[k], "Checking #{description}[#{k}]")
        end
      end
    end
  end

  def Test.print_stats()
    total = @@pass + @@fail

    puts("Tests passed: %d / %d (%.2f%%)" % [@@pass, total, 100 * @@pass/total.to_f])
    puts("Tests failed: %d / %d (%.2f%%)" % [@@fail, total, 100 * @@fail/total.to_f])
  end

  def Test.title(msg)
    puts()
    puts("** #{msg.upcase()} **")
  end

  def Test.test_create_binary()
    ######## BINARY
    title("Testing binary creation")

    binary = Binary.create(
      :name => "Binary Test",
      :comment => "Test binary",
      :data => BINARY_TEST_DATA,
    )

    assert_not_nil(binary, "Checking if the binary was created")
    assert_not_nil(binary.o, "Checking if the binary was returned")
    assert_type(binary.o[:binary_id], Fixnum, "Checking if the binary's id is numeric")
    assert_hash(binary.o, {
      :name    => "Binary Test",
      :comment => "Test binary",
      :data    => nil,
    }, "binary_create")

    @@binary_id = binary.o[:binary_id]
  end

  def Test.test_get_all_binaries()
    title("Testing retrieving all binaries (with data)")
    all_binaries = Binary.all(:with_data => true)
    assert(all_binaries.o[:binaries].length > 0, "Checking if at least one binary was returned")
    binary = all_binaries.o[:binaries].pop()

    assert_hash(binary, {
      :binary_id => @@binary_id,
      :name      => "Binary Test",
      :comment   => "Test binary",
      :data      => BINARY_TEST_DATA,
    } , "get_all_binaries")

    title("Testing retrieving all binaries (without data)")
    all_binaries = Binary.all(:with_data => false)
    assert(all_binaries.o[:binaries].length > 0, "Checking if at least one binary was returned")
    binary = all_binaries.o[:binaries].pop()

    assert_hash(binary, {
      :binary_id => @@binary_id,
      :name      => "Binary Test",
      :comment   => "Test binary",
      :data      => nil,
    } , "get_all_binaries")
  end

  def Test.test_find_binary()
    title("Testing searching for a binary (no data)")
    binary = Binary.find(@@binary_id)

    assert_not_nil(binary, "Checking if anything was returned")
    assert_hash(binary.o, {
      :binary_id => @@binary_id,
      :name      => "Binary Test",
      :comment   => "Test binary",
      :data      => nil
    }, "binary_find_1")

    title("Testing searching for a binary (with data)")
    binary = Binary.find(@@binary_id, :with_data => true)

    assert_not_nil(binary, "Checking if anything was returned")
    assert_hash(binary.o, {
      :binary_id => @@binary_id,
      :name      => "Binary Test",
      :comment   => "Test binary",
      :data      => BINARY_TEST_DATA,
    }, "binary_find_2")
  end

  def Test.test_save_binary()
    title("Testing saving the binary")
    binary = Binary.find(@@binary_id, :with_data => false)
    binary.o[:name] = "new binary name"
    binary.o[:comment] = "updated comment"
    saved = binary.save(:with_data => true)

    assert_not_nil(saved, "Checking if anything was returned")
    assert_hash(saved.o, {
      :binary_id => @@binary_id,
      :name      => "new binary name",
      :comment   => "updated comment",
      :data      => BINARY_TEST_DATA,
    }, "test_save_binary_1")

    title("Verifying the update by re-fetching the record")
    loaded = Binary.find(@@binary_id, :with_data => true)
    assert_not_nil(loaded, "Checking if anything was returned")
    assert_hash(loaded.o, {
      :binary_id => @@binary_id,
      :name      => "new binary name",
      :comment   => "updated comment",
      :data      => BINARY_TEST_DATA,
    }, "test_save_binary_1")
  end

  def Test.test_create_workspace()
    ######## WORKSPACE
    title("Create a workspace")
    workspace = Workspace.create(
      :binary_id    => @@binary_id,
      :name         => "test workspace"
    )

    assert_not_nil(workspace, "Checking if something was returned")
    assert_type(workspace.o[:workspace_id], Fixnum, "Checking if the workspace's id value is sane")
    assert_hash(workspace.o, {
      :name     => "test workspace",
      :segments => nil,
    }, "create_workspace")

    @@workspace_id = workspace.o[:workspace_id]
  end

  def Test.test_get_all_workspaces()
    title("Testing retrieving all workspaces")
    all_workspaces = Workspace.all(:binary_id => @@binary_id)

    assert_array(all_workspaces.o[:workspaces], [
      {
        :workspace_id => @@workspace_id,
        :binary_id    => @@binary_id,
        :name         => "test workspace",
        :revision     => 1,
      },
    ], "get_all_workspaces")
  end

  def Test.test_find_workspace()
    title("Finding the workspace")
    new_workspace = Workspace.find(@@workspace_id)
    assert_not_nil(new_workspace, "Checking if anything was returned")
    assert_hash(new_workspace.o, {
      :workspace_id  => @@workspace_id,
      :name          => "test workspace",
      :segments      => nil,
    }, "find_workspace")
  end

  def Test.test_update_workspace()
    title("Updating the workspace")

    workspace = Workspace.find(@@workspace_id)
    workspace.o[:name] = 'new name!?'
    updated = workspace.save()

    assert_not_nil(updated, "Checking if something was returned")
    assert_hash(updated.o, {
      :workspace_id  => @@workspace_id,
      :name     => "new name!?",
      :segments => nil,
    }, "update_workspace_1")

    title("Doing another search for the updated workspace, just to be sure")

    updated = Workspace.find(@@workspace_id, :with_segments => true)
    assert_not_nil(updated, "Checking if something was returned")
    assert_hash(updated.o, {
      :workspace_id  => @@workspace_id,
      :name          => "new name!?",
      :segments      => {},
    }, "update_workspace_1")
  end

  def Test.test_create_segment()
    workspace = Workspace.find(@@workspace_id)
    workspace.reset()

    start_revision = workspace.o[:revision]

    title("Creating a segment")
    segments = workspace.new_segment('create_segment_1', 0x00000000, "AAAAAAAA")
    assert_equal(segments.length, 1, "Checking if the right number of segments were returned")
    assert_hash(segments, {
      'create_segment_1' => { :address => 0, :data => nil},
    }, "create_segment_1")

    title("Creating another segment (only the new segment should be returned)")
    segments = workspace.new_segment('create_segment_2', 0x00000000, "AAAAAAAA")
    assert_equal(segments.length, 1, "Checking if the right number of segments were returned")
    assert_hash(segments, {
      'create_segment_2' => { :address => 0, :data => nil},
    }, "create_segment_2")

    title("Creating another segment and requesting all changes since the first segment")
    segments = workspace.new_segment('create_segment_3', 0x00000000, "AAAAAAAA", {}, { :since => start_revision })
    assert_equal(segments.length, 3, "Checking if the right number of segments were returned")
    assert_hash(segments, {
      'create_segment_1' => { :address => 0, :data => nil},
      'create_segment_2' => { :address => 0, :data => nil},
      'create_segment_3' => { :address => 0, :data => nil},
    }, "create_segment_3")
  end

  def Test.test_delete_segment()
    workspace = Workspace.find(@@workspace_id)
    workspace.reset()

    start_revision = workspace.o[:revision]

    title("Creating a segment")
    segments = workspace.new_segment('delete_segment_1', 0x00000000, "AAAAAAAA")
    assert_equal(segments.length, 1, "Checking if the right number of segments were returned")
    assert_hash(segments, {
      'delete_segment_1' => { :address => 0, :data => nil},
    }, "delete_segment_1")

    title("Creating another segment (only the new segment should be returned)")
    segments = workspace.new_segment('delete_segment_2', 0x00000000, "AAAAAAAA")
    assert_equal(segments.length, 1, "Checking if the right number of segments were returned")
    assert_hash(segments, {
      'delete_segment_2' => { :address => 0, :data => nil},
    }, "delete_segment_2")

    title("Deleting the second segment, nothing should be returned")
    result = workspace.delete_segment('delete_segment_2')
    assert_equal(result, {}, "Checking that nothing is returned")

    title("Creating another segment and requesting all changes since the first segment")
    segments = workspace.new_segment('delete_segment_3', 0x00000000, "AAAAAAAA", {}, { :since => start_revision })
    assert_equal(segments.length, 2, "Checking if the right number of segments were returned")
    assert_hash(segments, {
      'delete_segment_1' => { :address => 0, :data => nil},
      'delete_segment_3' => { :address => 0, :data => nil},
    }, "delete_segment_3")

    title("Deleting the third segment, and requesting all changes since the first segment")
    segments = workspace.delete_segment('delete_segment_3', {:since => start_revision})
    assert_equal(segments.length, 1, "Checking if the right number of segments were returned")
    assert_hash(segments, {
      'delete_segment_1' => { :address => 0, :data => nil},
    }, "delete_segment_4")
  end

  def Test.test_find_segments()
    title("Testing finding segments")

    workspace = Workspace.find(@@workspace_id)
    workspace.reset()

    segments = workspace.new_segment('s1', 0x00000000, "AAAAAAAA")

    title("Find segments (w/ default)")

    segments = workspace.get_segments('s1')
    assert_equal(segments.length(), 1, "Checking if the proper number of segments were returned")
    assert_hash(segments, {
      's1' => {
        :nodes => nil,
        :data  => nil,
      }
    }, "find_segments_1")

    title("Find segments (without data, without nodes)")
    segments = workspace.get_segments('s1', :with_data => false, :with_nodes => false)
    assert_equal(segments.length(), 1, "Checking if the proper number of segments were returned")
    assert_hash(segments, {
      's1' => {
        :nodes => nil,
        :data  => nil,
      }
    }, "find_segments_2")

    title("Find segments (without data, with nodes)")
    segments = workspace.get_segments('s1', :with_data => false, :with_nodes => true)
    assert_equal(segments.length(), 1, "Checking if the proper number of segments were returned")
    assert_hash(segments, {
      's1' => {
        :nodes => {},
        :data  => nil,
      }
    }, "find_segments_3")

    title("Find segments (with data, without nodes")
    segments = workspace.get_segments('s1', :with_data => true, :with_nodes => false)
    assert_equal(segments.length(), 1, "Checking if the proper number of segments were returned")
    assert_hash(segments, {
      's1' => {
        :nodes => nil,
        :data  => 'AAAAAAAA',
      }
    }, "find_segments_4")

    title("Find segments (with data, with nodes")
    segments = workspace.get_segments('s1', :with_data => true, :with_nodes => true)
    assert_equal(segments.length(), 1, "Checking if the proper number of segments were returned")
    assert_hash(segments, {
      's1' => {
        :nodes => {},
        :data  => 'AAAAAAAA',
      }
    }, "find_segments_5")

    title("Find segments (without segments, because YOLO)")
    segments = workspace.get_segments('s1', :with_segments => false)
    assert_nil(segments, "Checking that no segments were returned")

    title("Find all segments")
    segments = workspace.get_segments()
    assert_equal(segments.length(), 1, "Checking if the proper number of segments were returned")
    assert_hash(segments, {
      's1' => {
        :nodes => nil,
        :data  => nil,
      }
    }, "find_segments_1")

    title("Deleting the segment")
    result = workspace.delete_segment('s1')
    assert_equal(result, {}, "Checking if the segment was deleted")
    assert_equal(workspace.get_segments().length(), 0, "Checking again if the segment was deleted")
  end

  def Test.test_undo()
    title("Create segment")
    workspace = Workspace.find(@@workspace_id)
    workspace.reset()

    segments = workspace.new_segment('s1', 0x00000000, "AAAAAAAA")

    title("Verifying the undo log")
    assert_hash(workspace.get_undo_log, {
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
    }, "undo1")

    title("Deleting the segment")
    workspace.delete_segment('s1')
    assert_equal(workspace.get_segments().length(), 0, "Checking if the segment was deleted")

    title("Verifying the undo log")
    assert_hash(workspace.get_undo_log, {
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
    }, "undo2")

    title("Testing undo (should restore the deleted segment)")
    segments = workspace.undo(:with_data => true, :with_nodes => true)
    assert_equal(segments.length(), 1, "Checking if the number of segments returned was right")
    assert_hash(segments, {
      's1' => {
        :data => 'AAAAAAAA',
        :nodes => {},
      }
    }, 'undo2.5')

    title("Verifying the undo log")
    assert_hash(workspace.get_undo_log, {
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
    }, "undo3")

    title("Double-checking undo")
    segments = workspace.get_segments('s1', :with_data => true, :with_nodes => true)
    assert_equal(segments.length(), 1, "Checking if the proper number of segments were returned")
    assert_hash(segments, {
      's1' => {
        :data  => 'AAAAAAAA',
        :nodes => {},
      }
    }, 'undo3.5')

    title("Testing a second undo (should undo the segment's initial creation)")
    segments = workspace.undo(:with_data => true, :with_nodes => true)
    assert_type(segments, Hash, "Checking if redo returned properly")
    assert_equal(segments.keys.length(), 0, "Checking if redo successfully deleted the segment")

    assert_hash(workspace.get_undo_log, {
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
    }, "undo4")

    title("Testing redo (should restore the segment)")
    segments = workspace.redo(:with_data => true, :with_nodes => true)
    assert_equal(segments.length(), 1, "Checking if the segment was restored")
    assert_hash(segments, {
      's1' => {
        :data  => 'AAAAAAAA',
        :nodes => {},
      }
    }, 'undo4.5')

    assert_hash(workspace.get_undo_log, {
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
    }, "undo5")

    title("Double-checking redo")
    segments = workspace.get_segments('s1', :with_data => true, :with_nodes => true)
    assert_equal(segments.keys.length(), 1, "Checking if the proper number of segments were returned")
    assert_hash(segments, {
      's1' => {
        :data  => 'AAAAAAAA',
        :nodes => {},
      }
    }, 'undo5.5')

    title("Creating a segment to hopefully kill the redo buffer")
    segments = workspace.new_segment("deleteme", 0x00000000, "ABCDEFGH", {}, :since => 0)
    assert_equal(segments.length, 2, "Checking if both segments were returned (if this fails, :since is probably broken)")
    assert_hash(segments, {
      's1'       => {},
      'deleteme' => {},
    }, 'undo5.75')

    assert_hash(workspace.get_undo_log, {
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
    }, "undo6")

    title("Attempting a redo, which should fail")
    workspace.redo()
    segments = workspace.get_segments()
    assert_equal(segments.length, 2, "Checking that there are still two segments")
    assert_hash(segments, {
      's1' => {},
      'deleteme' => {},
    }, 'undo6.5')

    assert_hash(workspace.get_undo_log, {
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
    }, "undo7")

    title("Attempting another undo, which should delete the new segment")
    workspace.undo()
    segments = workspace.get_segments()
    assert_equal(segments.length, 1, "Checking if there are still the right number of segments")
    assert_not_nil(segments['s1'], "Checking if the first segment is still present")
    assert_nil(segments['deleteme'], "Checking if the new segment was undone")

    assert_hash(workspace.get_undo_log, {
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
    }, "undo8")

    title("Attempting a redo, which should restore the new segment")
    workspace.redo()
    segments = workspace.get_segments()
    assert_equal(segments.length, 2, "Checking if both segments are back")
    assert_hash(segments, {
      's1'       => {},
      'deleteme' => {},
    }, 'undo8.5')

    assert_hash(workspace.get_undo_log, {
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
    }, "undo9")

    title("Attempting another undo, which should delete the new segment *AGAIN*")
    workspace.undo()
    segments = workspace.get_segments()
    assert_equal(segments.length, 1, "Checking if there's one segment again")
    assert_not_nil(segments['s1'], "Checking if the first segment is still present")
    assert_nil(segments['deleteme'], "Checking if the new segment is gone again")

    title("Attempting a final undo, which should bring us back to the original state")
    workspace.undo()
    segments = workspace.get_segments()
    assert_equal(segments.length, 0, "Checking if all segments are gone")
  end

  def Test.test_nodes()
    title("Testing creating / deleting / undoing / redoing nodes")
    workspace = Workspace.find(@@workspace_id)
    workspace.reset()

    segment = workspace.new_segment('s2', 0x0000, "ABCDEFGH")
    assert_equal(segment.keys.length(), 1, "Checking if only the new segment exists")
    assert_not_nil(segment['s2'], "Checking that the segment was created")

    title("Finding the segment")
    segment = workspace.get_segment('s2', :with_nodes => true, :with_data => true)
    assert_type(segment, Hash, "Checking if the segment was returned")
    assert_type(segment[:nodes], Hash, "Checking if nodes are present")
    assert_hash(segment[:nodes], {
      0x0000 => { :address => 0x0000, :type => 'undefined' },
      0x0001 => { :address => 0x0001, :type => 'undefined' },
      0x0002 => { :address => 0x0002, :type => 'undefined' },
      0x0003 => { :address => 0x0003, :type => 'undefined' },
      0x0004 => { :address => 0x0004, :type => 'undefined' },
      0x0005 => { :address => 0x0005, :type => 'undefined' },
      0x0006 => { :address => 0x0006, :type => 'undefined' },
      0x0007 => { :address => 0x0007, :type => 'undefined' },
    }, 'nodes1', true)

    title("Creating a 32-bit node")
    result = workspace.new_node('s2', 0x0000, 'dword0', 4, 'value0', { :test => '123', :test2 => 456 }, [0x0004])
    assert_hash(result, {
      's2' => {
        :nodes => {
          0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => []       },
          0x0004 => { :type => 'undefined', :refs => nil,      :xrefs => [0x0000] },
        }
      }
    }, 'nodes2', true)

    title("Making sure there are exactly 5 nodes present")
    segment = workspace.get_segment('s2', :with_nodes => true, :with_data => true)
    assert_hash(segment[:nodes], {
      0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => [] },
      0x0004 => { :type => 'undefined', :refs => nil,      :xrefs => [0x0000] },
      0x0005 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0006 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0007 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
    }, "nodes3", true)

    title("Creating a non-overlapping 32-bit node")
    result = workspace.new_node('s2', 0x0004, 'dword4', 4, 'value4', { :test => 321, :test2 => '654' }, [0x0000])
    segment = result['s2']
    assert_hash(segment[:nodes], {
      0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => [0x0004] },
      0x0004 => { :type => 'dword4',    :refs => [0x0000], :xrefs => [0x0000] },
    }, "nodes4", true)

    title("Making sure both nodes are in good shape")
    segment = workspace.get_segment('s2', :with_nodes => true, :with_data => true)
    assert_hash(segment[:nodes], {
      0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => [0x0004] },
      0x0004 => { :type => 'dword4',    :refs => [0x0000], :xrefs => [0x0000] },
    }, "nodes5", true)

    title("Creating an overlapping 32-bit node")
    result = workspace.new_node('s2', 0x00000002, 'dword2', 4, 'value2', { :test => 321, :test2 => '654' }, [])
    assert_hash(result['s2'][:nodes], {
      # TODO: Undefined nodes shouldn't return nil for refs
      0x0000 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0001 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0002 => { :type => 'dword2',    :refs => [],  :xrefs => [] },
      0x0006 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0007 => { :type => 'undefined', :refs => nil, :xrefs => [] },
    }, "nodes6", true)

    title("Making sure it's still in good shape")
    segment = workspace.get_segment('s2', :with_nodes => true, :with_data => true)
    assert_hash(segment[:nodes], {
      0x0000 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0001 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0002 => { :type => 'dword2',    :refs => [],  :xrefs => [] },
      0x0006 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0007 => { :type => 'undefined', :refs => nil, :xrefs => [] },
    }, "nodes7", true)

    title("Undoing the third node")
    result = workspace.undo(:with_nodes => true) # TODO: why with_nodes
    assert_hash(result['s2'][:nodes], {
      0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => [0x0004] },
      0x0004 => { :type => 'dword4',    :refs => [0x0000], :xrefs => [0x0000] },
    }, "nodes8", true)

    title("Undoing the second node")
    result = workspace.undo(:with_nodes => true)
    assert_hash(result['s2'][:nodes], {
      0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => [] },
      0x0004 => { :type => 'undefined', :refs => nil,      :xrefs => [0x0000] },
      0x0005 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0006 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0007 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
    }, "nodes9", true)

    segment = workspace.get_segment('s2', :with_nodes => true)
    assert_hash(result['s2'][:nodes], {
      0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => [] },
      0x0004 => { :type => 'undefined', :refs => nil,      :xrefs => [0x0000] },
      0x0005 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0006 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0007 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
    }, "nodes10", true)

    title("Undoing the first node")
    result = workspace.undo(:with_nodes => true)
    assert_hash(result['s2'][:nodes], {
      0x0000 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0001 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0002 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0003 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0004 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
    }, "nodes11", true)

    segment = workspace.get_segment('s2', :with_nodes => true)
    assert_hash(segment[:nodes], {
      0x0000 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0001 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0002 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0003 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0004 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0005 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0006 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0007 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
    }, "nodes12", true)

    title("Redo: creating the first 32-bit node")
    result = workspace.redo(:with_nodes => true)
    assert_hash(result['s2'][:nodes], {
      0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => [] },
      0x0004 => { :type => 'undefined', :refs => nil,      :xrefs => [0x0000] },
    }, "nodes13", true)

    title("Making sure there are exactly 5 nodes present")
    segment = workspace.get_segment('s2', :with_nodes => true, :with_data => true)
    assert_hash(segment[:nodes], {
      0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => [] },
      0x0004 => { :type => 'undefined', :refs => nil,      :xrefs => [0x0000] },
      0x0005 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0006 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
      0x0007 => { :type => 'undefined', :refs => nil,      :xrefs => [] },
    }, "nodes14", true)

    title("Redo: creating a non-overlapping 32-bit node")
    result = workspace.redo(:with_data => true)
    assert_hash(result['s2'][:nodes], {
      0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => [0x0004] },
      0x0004 => { :type => 'dword4',    :refs => [0x0000], :xrefs => [0x0000] },
    }, "nodes15", true)

    title("Making sure both nodes are in good shape")
    segment = workspace.get_segment('s2', :with_nodes => true, :with_data => true)
    assert_hash(segment[:nodes], {
      0x0000 => { :type => 'dword0',    :refs => [0x0004], :xrefs => [0x0004] },
      0x0004 => { :type => 'dword4',    :refs => [0x0000], :xrefs => [0x0000] },
    }, "nodes16", true)

    title("Redo: creating an overlapping 32-bit node")
    result = workspace.redo(:with_data => true)
    assert_hash(result['s2'][:nodes], {
      0x0000 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0001 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0002 => { :type => 'dword2',    :refs => [],  :xrefs => [] },
      0x0006 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0007 => { :type => 'undefined', :refs => nil, :xrefs => [] },
    }, "nodes17", true)

    title("Making sure it's still in good shape")
    segment = workspace.get_segment('s2', :with_nodes => true, :with_data => true)
    assert_hash(segment[:nodes], {
      0x0000 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0001 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0002 => { :type => 'dword2',    :refs => [],  :xrefs => [] },
      0x0006 => { :type => 'undefined', :refs => nil, :xrefs => [] },
      0x0007 => { :type => 'undefined', :refs => nil, :xrefs => [] },
    }, "nodes18", true)
  end

  def Test.test_create_multiple_segments()
    title("Creating 4 segments at once")
    workspace = Workspace.find(@@workspace_id)
    workspace.reset()

    result = workspace.new_segments({
      'A' => { :address => 0,  :data => 'A' * 16, },
      'B' => { :address => 16, :data => 'B' * 16, },
      'C' => { :address => 32, :data => 'C' * 16, },
      'D' => { :address => 48, :data => 'D' * 16, },
    })
    assert_hash(result, {
      'A' => { :address => 0,  },
      'B' => { :address => 16, },
      'C' => { :address => 32, },
      'D' => { :address => 48, },
    }, "create_multiple_segments_1", true)

    result = workspace.undo()

    # Go back to a clean slate
    title("Creating 4 segments at once, and requesting data + nodes")
    result = workspace.new_segments({
      'A' => { :address => 0,  :data => 'A' * 16, },
      'B' => { :address => 16, :data => 'B' * 16, },
      'C' => { :address => 32, :data => 'C' * 16, },
      'D' => { :address => 48, :data => 'D' * 16, },
    }, :with_data => true, :with_nodes => true)
    assert_hash(result, {
      'A' => { :address => 0,  :data => 'A' * 16, :nodes => { 0  => {:type => 'undefined'}}, },
      'B' => { :address => 16, :data => 'B' * 16, :nodes => { 16 => {:type => 'undefined'}}, },
      'C' => { :address => 32, :data => 'C' * 16, :nodes => { 32 => {:type => 'undefined'}}, },
      'D' => { :address => 48, :data => 'D' * 16, :nodes => { 48 => {:type => 'undefined'}}, },
    }, "create_multiple_segments_2", true)

    # Go back to a clean slate
    result = workspace.undo()
  end

  def Test.test_create_multiple_nodes()
    title("Creating 4 nodes at once")
    workspace = Workspace.find(@@workspace_id)
    workspace.reset()

    segment = workspace.new_segment('A', 0x1000, "1111222233334444")
    assert_type(segment, Hash, "Checking if the segment returned properly")
    result = workspace.new_nodes('A', [
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
    result = workspace.delete_nodes('A', [0x1008])
    assert_hash(result, { 'A' => {
      :address => 0x1000,
      :nodes => {
        0x1008 => {:address => 0x1008, :type => 'undefined', :length => 1},
        0x1009 => {:address => 0x1009, :type => 'undefined', :length => 1},
        0x100a => {:address => 0x100a, :type => 'undefined', :length => 1},
        0x100b => {:address => 0x100b, :type => 'undefined', :length => 1},
      }
    }}, 'deleted_nodes')

    # Get all nodes to make sure it's sane
    assert_hash(workspace.get_segment('A', :with_nodes => true), { :nodes =>
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
  end

  def Test.test_xrefs()
    title("Testing cross-references")
    workspace = Workspace.find(@@workspace_id)
    workspace.reset()

    segment = workspace.new_segment('X', 0x0, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    assert_type(segment, Hash, "Checking if the segment returned properly")

    result = workspace.new_nodes('X', [
      {:address => 0,  :type => 'defined', :length => 4, :value => 'References 4 and 8',      :refs => [4, 8]},
      {:address => 4,  :type => 'defined', :length => 4, :value => 'References 0 and itself', :refs => [0, 4]},
      {:address => 8,  :type => 'defined', :length => 4, :value => 'References all others',   :refs => [0, 4, 8, 12]},
      {:address => 12, :type => 'defined', :length => 4, :value => 'References 0 and 16',     :refs => [0, 16]},
    ])

    assert_hash(result['X'][:nodes], {
      0  => {:type => 'defined',   :refs => [4, 8],         :xrefs => [4, 8, 12]},
      4  => {:type => 'defined',   :refs => [0, 4],         :xrefs => [0, 4, 8]},
      8  => {:type => 'defined',   :refs => [0, 4, 8, 12],  :xrefs => [0, 8]},
      12 => {:type => 'defined',   :refs => [0, 16],        :xrefs => [8]},
      16 => {:type => 'undefined', :refs => nil,            :xrefs => [12]},
    }, "xrefs1")

    title("Creating a new node with xrefs")
    result = workspace.new_nodes('X', [
      {:address => 0x0010, :type => 'defined', :length => 4, :value => 'References 0 and 12', :refs => [0, 12]},
    ])
    assert_hash(result['X'][:nodes], {
      0  => {:type => 'defined',   :refs => [4, 8],         :xrefs => [4, 8, 12, 16]},
      12 => {:type => 'defined',   :refs => [0, 16],        :xrefs => [8, 16]},
      16 => {:type => 'defined',   :refs => [0, 12],        :xrefs => [12]},
    }, "xrefs2", true)

    title("Deleting a node")
    result = workspace.delete_nodes('X', [0x0008])
    assert_hash(result['X'][:nodes], {
      0  => {:type => 'defined',   :refs => [4, 8],         :xrefs => [4, 12, 16]},
      4  => {:type => 'defined',   :refs => [0, 4],         :xrefs => [0, 4]},
      8  => {:type => 'undefined', :refs => nil,            :xrefs => [0]},
      9  => {:type => 'undefined', :refs => nil,            :xrefs => []},
      10 => {:type => 'undefined', :refs => nil,            :xrefs => []},
      11 => {:type => 'undefined', :refs => nil,            :xrefs => []},
      12 => {:type => 'defined',   :refs => [0, 16],        :xrefs => [16]},
    }, "xrefs3", true)

    title("Deleting another node")
    result = workspace.delete_nodes('X', [16])
    assert_hash(result['X'][:nodes], {
      0  => {:type => 'defined',   :refs => [4, 8],         :xrefs => [4, 12]},
      12 => {:type => 'defined',   :refs => [0, 16],        :xrefs => []},
      16 => {:type => 'undefined', :refs => nil,            :xrefs => [12]},
      17 => {:type => 'undefined', :refs => nil,            :xrefs => []},
      18 => {:type => 'undefined', :refs => nil,            :xrefs => []},
      19 => {:type => 'undefined', :refs => nil,            :xrefs => []},
    }, "xrefs4", true)

    title("Undoing the delete")
    result = workspace.undo()
    assert_hash(result['X'][:nodes], {
      0  => {:type => 'defined',   :refs => [4, 8],         :xrefs => [4, 12, 16]},
      12 => {:type => 'defined',   :refs => [0, 16],        :xrefs => [16]},
      16 => {:type => 'defined',   :refs => [0, 12],        :xrefs => [12]},
    }, "xrefs5", true)

    title("Re-doing the delete")
    result = workspace.redo()
    assert_hash(result['X'][:nodes], {
      0  => {:type => 'defined',   :refs => [4, 8],         :xrefs => [4, 12]},
      12 => {:type => 'defined',   :refs => [0, 16],        :xrefs => []},
      16 => {:type => 'undefined', :refs => nil,            :xrefs => [12]},
      17 => {:type => 'undefined', :refs => nil,            :xrefs => []},
      18 => {:type => 'undefined', :refs => nil,            :xrefs => []},
      19 => {:type => 'undefined', :refs => nil,            :xrefs => []},
    }, "xrefs6", true)

    title("Creating another xrefs node that has xrefs on uneven boundaries")
    result = workspace.new_nodes('X', [
      {:address => 20, :type => 'defined', :length => 4, :value => 'References 2, 4, 10, and 12', :refs => [2, 4, 10, 12]},
    ])
    assert_hash(result['X'][:nodes], {
      0  => {:type => 'defined',   :refs => [4, 8],         :xrefs => [4, 12, 20]},
      4  => {:type => 'defined',   :refs => [0, 4],         :xrefs => [0, 4, 20]},
      10 => {:type => 'undefined', :refs => nil,            :xrefs => [20]},
      12 => {:type => 'defined',   :refs => [0, 16],        :xrefs => [20]},
      20 => {:type => 'defined',   :refs => [2, 4, 10, 12], :xrefs => []},
    }, "xrefs7", true)

    title("Deleting a node that has a xref in the middle")
    result = workspace.delete_nodes('X', [0x0000])
    assert_hash(result['X'][:nodes], {
      0  => {:type => 'undefined', :refs => nil,            :xrefs => [4, 12]},
      1  => {:type => 'undefined', :refs => nil,            :xrefs => []},
      2  => {:type => 'undefined', :refs => nil,            :xrefs => [20]},
      3  => {:type => 'undefined', :refs => nil,            :xrefs => []},

      4  => {:type => 'defined',   :refs => [0, 4],         :xrefs => [4, 20]},
      8  => {:type => 'undefined', :refs => nil,            :xrefs => []},
    }, "xrefs8", true)

    title("Re-creating a node that covers a now-undefined node")
    result = workspace.new_nodes('X', [
      {:address => 8, :type => 'defined', :length => 4, :value => 'References 0, 4, 8, and 12', :refs => [0, 4, 8, 12]},
    ])
    assert_hash(result['X'][:nodes], {
      0  => {:type => 'undefined', :refs => nil,            :xrefs => [4, 8, 12]},
      4  => {:type => 'defined',   :refs => [0, 4],         :xrefs => [4, 8, 20]},
      8  => {:type => 'defined',   :refs => [0, 4, 8, 12],  :xrefs => [8, 20]},
      12 => {:type => 'defined',   :refs => [0, 16],        :xrefs => [8, 20]},
    }, "xrefs9", true)

    title("Deleting the segment")
    result = workspace.delete_segment('X')
    assert_equal(result, {}, "Checking if the segment was deleted")

    title("Undoing segment delete")
    result = workspace.undo()
    assert_hash(result['X'][:nodes], {
      0  => {:type => 'undefined', :refs => nil,            :xrefs => [4, 8, 12]},
      1  => {:type => 'undefined', :refs => nil,            :xrefs => []},
      2  => {:type => 'undefined', :refs => nil,            :xrefs => [20]},
      3  => {:type => 'undefined', :refs => nil,            :xrefs => []},
      4  => {:type => 'defined',   :refs => [0, 4],         :xrefs => [4, 8, 20]},
      8  => {:type => 'defined',   :refs => [0, 4, 8, 12],  :xrefs => [8, 20]},
      12 => {:type => 'defined',   :refs => [0, 16],        :xrefs => [8, 20]},
      16 => {:type => 'undefined', :refs => nil,            :xrefs => [12]},
      17 => {:type => 'undefined', :refs => nil,            :xrefs => []},
      18 => {:type => 'undefined', :refs => nil,            :xrefs => []},
      19 => {:type => 'undefined', :refs => nil,            :xrefs => []},
      20 => {:type => 'defined',   :refs => [2, 4, 10, 12], :xrefs => []},
      24 => {:type => 'undefined', :refs => nil,            :xrefs => []},
      25 => {:type => 'undefined', :refs => nil,            :xrefs => []},
    }, "xrefs10", true)

    title("Re-doing segment delete")
    result = workspace.redo()
    assert_equal(result, {}, "Checking if the segment was deleted")
  end

  def Test.test_segment_details()
    title("Testing setting arbitrary properties in segments")
    workspace = Workspace.find(@@workspace_id)
    workspace.reset()

    segment = workspace.new_segment('Y', 0x0, "ABCDEFGHIJKLMNOPQRSTUVWXYZ", {:a => "b"})
    assert_type(segment, Hash, "Checking if the segment returned properly")
    assert_hash(segment, {
      'Y' => { :address => 0, :data => nil, :details => {:a => 'b'}},
    }, "segment_details_1")
  end

  def Test.test_properties()
    binary = Binary.find(@@binary_id)

    binary.set_property(:test,  123)
    binary.set_property(:test2, "1234")
    assert_equal(binary.get_property(:test),  123,    "Checking if an integer property works")
    assert_equal(binary.get_property(:test2), "1234", "Checking if a string property works")

    binary.set_property(:test, [1, 2, 3])
    assert_array(binary.get_property(:test), [1, 2, 3], "property_overwrite_array_1")

    binary.set_property(:test, { :a => "b", :c => 123 })
    assert_hash(binary.get_property(:test), { :a => "b", :c => 123 }, "property_store_hash_1", true)

    binary.set_properties({ :a => 'b', :c => 'd', :e => 1 })
    assert_hash(binary.get_properties([:a, :c, :e]), {
      :a => 'b',
      :c => 'd',
      :e => 1,
    }, "property_multiple_hashes_1", true)
    assert_hash(binary.get_properties(), {
      :a => 'b',
      :c => 'd',
      :e => 1,
      :test => { :a => "b", :c => 123 },
      :test2 => "1234",
    }, "property_all_properties_1", true)

    binary.delete_property(:test)
    assert_hash(binary.get_properties(), {
      :a => 'b',
      :c => 'd',
      :e => 1,
      :test2 => "1234",
    }, "property_delete_value_1", true)

    workspace = Workspace.find(@@workspace_id)

    workspace.set_property(:test,  123)
    workspace.set_property(:test2, "1234")
    assert_equal(workspace.get_property(:test),  123,    "Checking if an integer property works")
    assert_equal(workspace.get_property(:test2), "1234", "Checking if a string property works")

    workspace.set_property(:test, [1, 2, 3])
    assert_array(workspace.get_property(:test), [1, 2, 3], "property_overwrite_array_3")

    workspace.set_property(:test, { :a => "b", :c => 123 })
    assert_hash(workspace.get_property(:test), { :a => "b", :c => 123 }, "property_store_hash_3", true)

    workspace.set_properties({ :a => 'b', :c => 'd', :e => 1 })
    assert_hash(workspace.get_properties([:a, :c, :e]), {
      :a => 'b',
      :c => 'd',
      :e => 1,
    }, "property_multiple_hashes_3", true)
    assert_hash(workspace.get_properties(), {
      :a => 'b',
      :c => 'd',
      :e => 1,
      :test => { :a => "b", :c => 123 },
      :test2 => "1234",
    }, "property_all_properties_3", true)

    workspace.delete_property(:test)
    assert_hash(workspace.get_properties(), {
      :a => 'b',
      :c => 'd',
      :e => 1,
      :test2 => "1234",
    }, "property_delete_value_3", true)
  end

  def Test.test()
    begin
      # Tests for binaries
      test_create_binary() # Mandatory (sets @@binary_id)
      test_get_all_binaries()
      test_find_binary()
      test_save_binary()

      # Tests for workspaces
      test_create_workspace() # Mandatory (sets @@workspace_id)
      test_get_all_workspaces()
      test_find_workspace()
      test_update_workspace()
      test_create_segment()
      test_delete_segment()
      test_find_segments()
      test_undo()
      test_nodes()
      test_create_multiple_segments()
      test_create_multiple_nodes()
      test_xrefs()
      test_segment_details()

      # Tests for everything
      test_properties()

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
        if(!@@workspace_id.nil?)
          title("Deleting workspace")
          result = Workspace.find(@@workspace_id).delete()
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
        if(!@@binary_id.nil?)
          result = Binary.find(@@binary_id).delete()
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
  end
end
