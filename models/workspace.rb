# workspace.rb
# Create on November 4, 2014
# By Ron Bowes

require 'models/model'

class Workspace < Model
#  def set(params)
#    return post_stuff("/workspaces/:workspace_id/set", params)
#  end
#
#  def get(params)
#    result = get_stuff("/workspaces/:workspace_id/get", params)
#
#    return result.value
#  end

  def initialize(params = {})
    super(params)
  end

  def Workspace.find(id, params = {})
    return get_stuff(Workspace, '/workspaces/:workspace_id', params.merge({ :workspace_id => id }))
  end

  def Workspace.create(params)
    return post_stuff(Workspace, '/binaries/:binary_id/new_workspace', params)
  end

  def Workspace.all(params = {})
    return get_stuff(Workspace, '/binaries/:binary_id/workspaces', params)
  end

  def save(params = {})
    return put_stuff('/workspaces/:workspace_id', params.merge(self.o))
  end

  def delete(params = {})
    return delete_stuff('/workspaces/:workspace_id', params.merge({:workspace_id => self.o[:workspace_id]}))
  end
end
