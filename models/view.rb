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

  def delete_segment(name)
    return post_stuff("/views/:view_id/delete_segment", {
      :segment => name,
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

  def delete_node()
    return post_stuff("/views/:view_id/delete_segment", {
      :segment => name,
    })
  end

  def delete()
    puts(inspect())
    return delete_stuff("/views/:view_id")
  end
end
