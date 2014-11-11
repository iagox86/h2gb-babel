# view.rb
# Create on November 4, 2014
# By Ron Bowes

class View < ActiveRestClient::Base
  base_url HOST
  request_body_type :json

  include ActiveRestExtras

  get    :all,            "/workspaces/:workspace_id/views"
  get    :find,           "/views/:view_id"
  put    :save,           "/views/:view_id"
  post   :create,         "/workspaces/:workspace_id/new_view"

  def new_segment(name, address, file_address, data)
    return post_stuff("/views/:view_id/new_segment", {
      :name         => name,
      :address      => address,
      :file_address => file_address,
      :data         => Base64.encode64(data),
    })
  end

  # name can be a string or an array
  def delete_segment(name)
    return post_stuff("/views/:view_id/delete_segment", {
      :segments => name,
    })
  end

  def new_node(address, type, length, value, details, references)
    return post_stuff("/views/:view_id/create_node", {
      :address      => address,
      :type         => type,
      :length       => length,
      :value        => value,
      :details      => details,
      :references   => references,
    })
  end

  def get_segments(names, params = {})
    segments = get_stuff("/views/:view_id/segments", {
      :names      => names,
      :with_nodes => params[:with_nodes],
      :with_data  => params[:with_data],
    })

    if(segments.nil? || segments.segments.nil?)
      raise(Exception, "Couldn't find the segment!")
    end

    segments = segments.segments
    segments.each do |s|
      if(!s.data.nil?)
        s.data = Base64.decode64(s.data)
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
      :segment => name,
    })
  end

  def delete()
    puts(inspect())
    return delete_stuff("/views/:view_id")
  end
end
