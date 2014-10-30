require 'rubygems'
require 'active_rest_client'
require 'cgi' # for URI::encode()

HOST = ARGV[0] || "http://localhost:9292"

module ActiveRestExtras
  def format_url(url, params)
    @attributes.each_pair do |k, v|
      url = url.gsub(":#{k}", v.to_s)
    end

    params.each_pair do |k, v|
      if(!url.index(":#{k}").nil?)
        url = url.gsub(":#{k}", params.delete(k))
      end
    end

    return url
  end

  def post_stuff(url, params)
    url = format_url(url, params)

    return Workspace._request(HOST + url, :post, params)
  end

  def get_stuff(url, params)
    url = format_url(url, params) + "?"

    params.each_pair do |k, v|
      url += params.to_query()
    end

    return Workspace._request(HOST + url, :get)
  end
end

class Binary < ActiveRestClient::Base
  base_url HOST
  request_body_type :json

  get    :all,    "/binaries"
  get    :find,   "/binaries/:binary_id"
  put    :save,   "/binaries/:binary_id"
  post   :create, "/binaries"
  delete :delete, "/binaries/:binary_id"

  # Transparently encode base64 in outbound requests
  before_request do |name, request|
    # Convert 'data' to base64, if it's present
    if(!request.post_params[:data].nil?)
      request.post_params[:data] = Base64.encode64(request.post_params[:data])
    end
  end

  # Transparently decode base64 in the server's response
  def Binary.find(id)
    b = super(id)
    b.data = Base64.decode64(b.data)
    return b
  end
end


class Workspace < ActiveRestClient::Base
  base_url HOST
  request_body_type :json

  include ActiveRestExtras

  get    :all,            "/binaries/:binary_id/workspaces"
  get    :find,           "/workspaces/:workspace_id"
  put    :save,           "/workspaces/:workspace_id"
  post   :create,         "/binaries/:binary_id/new_workspace"
  delete :delete,         "/workspaces/:workspace_id"

  def set(params)
    return post_stuff("/workspace/:workspace_id/set", params)
  end

  def get(params)
    result = get_stuff("/workspace/:workspace_id/get", params)

    return result.value
  end
end

class Memory < ActiveRestClient::Base
  base_url HOST
  request_body_type :json

  get    :all,            "/workspaces/:workspace_id/memories"
  get    :find,           "/memory/:memory_id"
  put    :save,           "/memory/:memory_id"
  post   :create,         "/workspaces/:workspace_id/new_memory"
  delete :delete,         "/binaries/:memory_id"

  def new_segment(name, address, file_address, data)
    return post_stuff("/memory/:memory_id/new_segment", {
      :name         => name,
      :address      => address,
      :file_address => file_address,
      :data         => Base64.encode64(data),
    })
  end

  def delete_segment(name)
    return post_stuff("/memory/:memory_id/delete_segment", {
      :segment => name,
    })
  end

  def new_node(address, type, length, value, details, references)
    return post_stuff("/memory/:memory_id/create_node", {
      :address      => address,
      :type         => type,
      :length       => length,
      :value        => value,
      :details      => details,
      :references   => references,
    })
  end

  def delete_node()
    return post_stuff("/memory/:memory_id/delete_segment", {
      :segment => name,
    })
  end
end

puts()
puts("** CREATE A BINARY")
binary = Binary.create(
  :name => "Binary Test",
  :comment => "Test binary",
  :data => Base64.encode64("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"),
)
if(!binary.id)
  puts("A valid binary wasn't returned!")
  puts("We got: #{binary.inspect}")
  exit
end
puts(binary.inspect)
puts("BINARY_ID: %d" % binary.id)

puts()
puts("** GET ALL BINARIES (should include the new one)")
all_binaries = Binary.all()
good = false
all_binaries.binaries.each do |b|
  if(b.id == binary.id)
    good = true
    puts("  * Found our new binary!")
  end
end
if(!good)
  puts("Couldn't find out new binary!")
  exit
end

puts()
puts("** FIND A BINARY")
binary_again = Binary.find(:binary_id => binary.id)
puts(binary_again.inspect)
binary = binary_again

# TODO: Test the update

puts()
puts("** CREATE A WORKSPACE")
workspace = Workspace.create(:binary_id => binary.id, :name => "test workspace")
puts(workspace.inspect)
if(!workspace.id)
  puts("A valid workspace wasn't returned!")
  puts("We got: #{workspace.inspect}")
  exit
end
puts("WORKSPACE_ID: %d" % workspace.id)

puts()
puts("** LIST ALL WORKSPACES")
workspaces = Workspace.all(:binary_id => binary.id)
if(workspaces[:workspaces].count != 1)
  puts("We should have exactly one workspace under our new binary, but we have #{workspaces[:workspaces].length} instead!")
  exit
end
workspaces[:workspaces].each do |w|
  if(w.id != workspace.id)
    puts("The workspace returned by 'all' didn't have the same id as the new workspace!")
    exit
  end
  puts(w.inspect)
end

puts()
puts("** FIND THE WORKSPACE")
workspace = Workspace.find(:workspace_id => workspace.id)
puts(workspace.inspect)

# TODO: Test the update

# TODO: Test the get / set

puts()
puts("** CREATE MEMORY")
memory = Memory.create(:workspace_id => workspace.id)
puts(memory.inspect)

puts()
puts("** LIST MEMORIES")
memories = Memory.all(:workspace_id => workspace.id)
puts(memories.inspect)
if(memories[:memories].count != 1)
  puts("Exactly 1 result wasn't returned as expected! Instead, #{memories[:memories].count} were returned")
end
memories[:memories].each do |m|
  if(m.id != memory.memory_id)
    puts("The memory returned by 'all' didn't have the same id as the new memory!")
    puts(m.id)
    puts(memory.memory_id)
    exit
  end
end


puts()
puts("** FIND MEMORY")
memory = Memory.find(:memory_id => memory.memory_id)
puts(memory.inspect)


# TODO: Create segments / nodes

#puts()
#puts("** DELETING MEMORY")
#
#puts("** DELETE THE WORKSPACE")
#puts(workspace.inspect)
#puts workspace.delete()
#
#puts()
#puts("** DELETE THE BINARY")
#puts binary.delete().inspect
