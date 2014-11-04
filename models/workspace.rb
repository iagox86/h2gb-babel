# workspace.rb
# Create on November 4, 2014
# By Ron Bowes

class Workspace < ActiveRestClient::Base
  base_url HOST
  request_body_type :json

  include ActiveRestExtras

  get    :all,            "/binaries/:binary_id/workspaces"
  get    :find,           "/workspaces/:workspace_id"
  put    :save,           "/workspaces/:workspace_id"
  post   :create,         "/binaries/:binary_id/new_workspace"

  def set(params)
    return post_stuff("/workspaces/:workspace_id/set", params)
  end

  def get(params)
    result = get_stuff("/workspaces/:workspace_id/get", params)

    return result.value
  end

  def delete()
    return delete_stuff("/workspaces/:workspace_id", {:workspace_id => self.id})
  end
end
