# workspace.rb
# Create on November 4, 2014
# By Ron Bowes

require 'models/model'

class Workspace < Model
  def initialize(params = {})
    super(params)
  end

  def Workspace.find(id, params = {})
    return get_stuff(Workspace, '/workspaces/:workspace_id', params.merge({ :workspace_id => id }))
  end

  def edit_segments()
    if(@o.is_a?(Hash))
      if(@o[:segments].nil?)
        return
      end

      @o[:segments].each() do |segment|
        yield(segment)
      end
    end
  end

  def array_to_hash(array, key)
    result = {}
    array.each do |v|
      result[v.delete(key)] = v
    end

    return result
  end

  def hash_to_array(hash, key)
    result = []

    hash.each_pair do |k, v|
      result << v.merge(key => k)
    end

    return result
  end

  def after_request()
    # Fix the segments up, as needed
    edit_segments() do |segment|
      # If there's data, automatically do the base64 decode
      if(!segment[:data].nil?)
        segment[:data] = Base64.decode64(segment[:data])
      end

      # Decode the raw data in the nodes
      if(!segment[:nodes].nil?)
        fixed = {}
        segment[:nodes].each_pair do |k, v|
          # Fix the base64 raw data
          v[:raw] = Base64.decode64(v[:raw])

          # Convert the key to an integer value
          fixed[k.to_s.to_i] = v
        end

        segment[:nodes] = fixed
      end
      segment # return
    end

    # Convert the segments into a hash
    if(@o.is_a?(Hash))
      if(!@o[:segments].nil?)
        @o[:segments] = array_to_hash(@o[:segments], :name)
      end
    end
  end

  def Workspace.create(params)
    require_param(params, :binary_id)
    return post_stuff(Workspace, '/binaries/:binary_id/new_workspace', params)
  end

  def Workspace.all(params = {})
    require_param(params, :binary_id)
    return get_stuff(Workspace, '/binaries/:binary_id/workspaces', params)
  end

  def save(params = {})
    return put_stuff('/workspaces/:workspace_id', params.merge(self.o)) # TODO: Is this merge necessary?
  end

  def delete(params = {})
    return delete_stuff('/workspaces/:workspace_id', params.merge({:workspace_id => self.o[:workspace_id]}))
  end

  def undo(params = {})
    return post_stuff('/workspaces/:workspace_id/undo', params.merge({:workspace_id => self.o[:workspace_id]})).o[:segments]
  end

  def redo(params = {})
    return post_stuff('/workspaces/:workspace_id/redo', params.merge({:workspace_id => self.o[:workspace_id]})).o[:segments]
  end

  def new_segment(name, address, data, details = {}, params = {})
    result = post_stuff("/workspaces/:workspace_id/new_segments", {
      :workspace_id      => self.o[:workspace_id],
      :segments     => [
        :name         => name,
        :address      => address,
        :data         => Base64.encode64(data),
        :details      => details,
      ]
    }.merge(params))

    return result.o[:segments]
  end

  def new_segments(segments, params = {})
    segments.each_value do |segment|
      segment[:data] = Base64.encode64(segment[:data])
    end

    result = post_stuff("/workspaces/:workspace_id/new_segments", {
      :workspace_id => self.o[:workspace_id],
      :segments     => hash_to_array(segments, :name)
    }.merge(params)).o[:segments]

    return result
  end

  def delete_segment(name, params = {})
    return post_stuff("/workspaces/:workspace_id/delete_segments", {
      :workspace_id  => self.o[:workspace_id],
      :segments => [name],
    }.merge(params)).o[:segments]
  end

  def delete_all_segments(params = {})
    return post_stuff("/workspaces/:workspace_id/delete_all_segments", {
      :workspace_id  => self.o[:workspace_id],
    }.merge(params)).o[:segments]
  end

  def delete_segments(names, params = {})
    return post_stuff("/workspaces/:workspace_id/delete_segments", {
      :workspace_id  => self.o[:workspace_id],
      :segments => names,
    }.merge(params)).o[:segments]
  end

  def new_node(segment, address, type, length, value, details, references, params = {})
    return post_stuff("/workspaces/:workspace_id/new_nodes", { 
      :workspace_id => self.o[:workspace_id],
      :segment => segment,
      :nodes => [{
        :address => address,
        :type    => type,
        :length  => length,
        :value   => value,
        :details => details,
        :refs    => references,
    }]}.merge(params)).o[:segments]
  end

  def new_nodes(segment, nodes, params = {})
    return post_stuff("/workspaces/:workspace_id/new_nodes", { 
      :workspace_id => self.o[:workspace_id],
      :segment => segment,
      :nodes => nodes
    }.merge(params)).o[:segments]
  end

  def delete_nodes(segment, addresses)
    if(!addresses.is_a?(Array))
      addresses = [addresses]
    end

    return post_stuff("/workspaces/:workspace_id/delete_nodes", {
      :workspace_id => self.o[:workspace_id],
      :segment => segment,
      :addresses => addresses,
    }).o[:segments]
  end

  def get_all_segments(params = {})
    return get_stuff("/workspaces/:workspace_id/segments", {
      :workspace_id       => self.o[:workspace_id],
    }.merge(params)).o[:segments]
  end

  def get_segments(names = nil, params = {})
    return get_stuff("/workspaces/:workspace_id/segments", {
      :workspace_id       => self.o[:workspace_id],
      :names         => names,
    }.merge(params)).o[:segments]
  end

  def get_segment(name, params = {})
    if(!name.is_a?(String))
      raise(Exception, "The name parameter should probably be a String")
    end

    result = get_segments(name, params)
    if(result.size() == 0)
      raise(Exception, "Couldn't find a segment with that name!")
    end
    if(result.size() > 1)
      raise(Exception, "More than one result had that name! (Note: that shouldn't be possible...)")
    end
    if(result[name].nil?)
      raise(Exception, "One segment was returned, but it wasn't the right one... #{result.keys.pop}")
    end

    # Pull out the one entry we wanted
    return result[name]
  end

  def get_undo_log(params = {})
    return get_stuff("/workspaces/:workspace_id/debug/undo_log", {
      :workspace_id => self.o[:workspace_id]
    }.merge(params)).o
  end

  def clear_undo_log(params = {})
    return post_stuff("/workspaces/:workspace_id/clear_undo_log", {
      :workspace_id => self.o[:workspace_id]
    }.merge(params)).o
  end

  # Mostly for testing, so I can get the workspace into a clean state
  def reset()
    delete_all_segments()
    clear_undo_log()
  end

  def print()
    segments = get_segments(nil, :with_nodes => true, :with_data => true)

    segments.each_pair do |name, segment|
      last_address = nil
      segment[:nodes].keys.sort.each do |address|
        node = segment[:nodes][address]

        raw = node[:raw].unpack("H*").pop
        raw = raw + (" " * (12 - raw.length()))

        xrefs = ''
        node[:xrefs].delete(last_address)
        if(node[:xrefs] && node[:xrefs].length > 0)
          xrefs = node[:xrefs] ? (' XREFS: %s' % node[:xrefs].map() { |x| '0x%x' % x }.join(", ")) : ""
        end
        puts("%s:%08x %s %s %s" % [segment[:name], node[:address], raw, node[:value], xrefs])

        last_address = address
      end
    end
  end

  def set_properties(hash, params = {})
    if(!hash.is_a?(Hash))
      raise(Exception, "set_properties() requires a hash")
    end

    return post_stuff('/workspaces/:workspace_id/set_properties', {
      :workspace_id => self.o[:workspace_id],
      :properties => hash,
    }.merge(params)).o
  end

  def set_property(key, value, params = {})
    return set_properties({key=>value}, params)
  end

  def delete_property(key, params = {})
    return set_property(key, nil, params)
  end

  def get_properties(keys = nil, params = {})
    if(!keys.nil? && !keys.is_a?(Array))
      raise(Exception, "WARNING: 'keys' needs to be an array")
    end

    result = post_stuff('/workspaces/:workspace_id/get_properties', {
      :workspace_id => self.o[:workspace_id],
      :keys => keys,
    }.merge(params))

    return result.o
  end

  def get_property(key, params = {})
    return get_properties([key], params)[key]
  end
end
