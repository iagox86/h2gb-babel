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
    return post_stuff('/views/:view_id/undo', params.merge({:view_id => self.o[:view_id]}))
  end

  def redo(params = {})
    return post_stuff('/views/:view_id/redo', params.merge({:view_id => self.o[:view_id]}))
  end

  def new_segment(name, address, file_address, data)
    return post_stuff("/views/:view_id/new_segment", {
      :view_id      => self.o[:view_id],
      :name         => name,
      :address      => address,
      :file_address => file_address,
      :data         => Base64.encode64(data),
    })
  end

  # name can be a string or an array
  def delete_segment(name)
    return post_stuff("/views/:view_id/delete_segment", {
      :view_id  => self.o[:view_id],
      :segments => name,
    })
  end

  def new_node(address, type, length, value, details, references)
    return post_stuff("/views/:view_id/create_node", {
      :view_id      => self.o[:view_id],
      :address      => address,
      :type         => type,
      :length       => length,
      :value        => value,
      :details      => details,
      :references   => references,
    })
  end

  def get_segments(names = nil, params = {})
    segments = get_stuff("/views/:view_id/segments", {
      :view_id    => self.o[:view_id],
      :names      => names,
      :with_nodes => params[:with_nodes],
      :with_data  => params[:with_data],
    })

    segments = segments.o[:segments]
    segments.each do |s|
      if(!s[:data].nil?)
        s[:data] = Base64.decode64(s[:data])
      end
    end

    return segments
  end

  def get_segment(name, params = {})
    if(!name.is_a?(String))
      raise(Exception, "The name parameter should probably be a string")
    end

    result = get_segments(name, params)
    if(result.size() == 0)
      raise(Exception, "Couldn't find a segment with that name!")
    end
    if(result.size() > 1)
      raise(Exception, "More than one result had that name!")
    end

    return result[0]
  end


  def delete_node(name)
    return post_stuff("/views/:view_id/delete_segment", {
      :view_id => self.o[:view_id],
      :segment => name,
    })
  end
end
