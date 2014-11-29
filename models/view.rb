# view.rb
# Create on November 4, 2014
# By Ron Bowes

require 'models/model'

class View < Model
  def initialize(params = {})
    super(params)
  end

  def View.find(id, params = {})
    return get_stuff(View, '/views/:view_id', params.merge({ :view_id => id }))
  end

  def edit_segments()
    if(@o[:segments].nil?)
      return
    end

    @o[:segments].each() do |segment|
      yield(segment)
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
    if(!@o[:segments].nil?)
      @o[:segments] = array_to_hash(@o[:segments], :name)
    end
  end

  def View.create(params)
    return post_stuff(View, '/workspaces/:workspace_id/new_view', params)
  end

  def View.all(params = {})
    return get_stuff(View, '/workspaces/:workspace_id/views', params)
  end

  def save(params = {})
    return put_stuff('/views/:view_id', params.merge(self.o)) # TODO: Is this merge necessary?
  end

  def delete(params = {})
    return delete_stuff('/views/:view_id', params.merge({:view_id => self.o[:view_id]}))
  end

  def undo(params = {})
    return post_stuff('/views/:view_id/undo', params.merge({:view_id => self.o[:view_id]})).o[:segments]
  end

  def redo(params = {})
    return post_stuff('/views/:view_id/redo', params.merge({:view_id => self.o[:view_id]})).o[:segments]
  end

  def new_segment(name, address, file_address, data, params = {})
    result = post_stuff("/views/:view_id/new_segments", {
      :view_id      => self.o[:view_id],
      :segments     => [
        :name         => name,
        :address      => address,
        :file_address => file_address,
        :data         => Base64.encode64(data),
      ]
    }.merge(params))

    return result.o[:segments]
  end

  def new_segments(segments, params = {})
    segments.each_value do |segment|
      segment[:data] = Base64.encode64(segment[:data])
    end

    result = post_stuff("/views/:view_id/new_segments", {
      :view_id      => self.o[:view_id],
      :segments     => hash_to_array(segments, :name)
    }.merge(params)).o[:segments]

    return result
  end

  def delete_segment(name)
    return post_stuff("/views/:view_id/delete_segments", {
      :view_id  => self.o[:view_id],
      :segments => [name],
    }).o[:segments]
  end

  def delete_segments(names)
    return post_stuff("/views/:view_id/delete_segments", {
      :view_id  => self.o[:view_id],
      :segments => names,
    }).o[:segments]
  end

  def new_node(segment, address, type, length, value, details, references, params = {})
    return post_stuff("/views/:view_id/new_nodes", { 
      :view_id => self.o[:view_id],
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
    return post_stuff("/views/:view_id/new_nodes", { 
      :view_id => self.o[:view_id],
      :segment => segment,
      :nodes => nodes
    }.merge(params)).o[:segments]
  end

  def delete_node(name)
    return post_stuff("/views/:view_id/delete_nodes", {
      :view_id => self.o[:view_id],
      :segment => [name],
    }).o
  end

  def delete_nodes(names)
    return post_stuff("/views/:view_id/delete_nodes", {
      :view_id => self.o[:view_id],
      :segment => names,
    }).o
  end

  def get_segments(names = nil, params = {})
    return get_stuff("/views/:view_id/segments", {
      :view_id       => self.o[:view_id],
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
    return get_stuff("/views/:view_id/debug/undo_log", {
      :view_id => self.o[:view_id]
    }.merge(params)).o
  end

  def print()
    segments = get_segments(nil, :with_nodes => true, :with_data => true)

    segments.each do |segment|
      segment[:nodes].each do |node|
        raw = Base64.decode64(node[:raw])
        raw = raw + (" " * (12 - raw.length()))

        if(node[:xrefs])
          xrefs = node[:xrefs] ? (' XREFS: %s' % node[:xrefs].map() { |x| '0x%x' % x }.join(", ")) : ""
        end
        puts("%s:%08x %s %s [%s]%s" % [segment[:name], node[:address], raw, node[:value], node[:type], xrefs])
      end
    end
  end
end
