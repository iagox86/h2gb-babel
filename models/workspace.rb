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
