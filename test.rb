require 'rubygems'
require 'active_rest_client'
require 'cgi' # for URI::encode()

HOST = ARGV[0] || "http://localhost:9292"

class Binary < ActiveRestClient::Base
  base_url HOST
  request_body_type :json

  get  :all,              "/binaries"
  get  :find,             "/binary/:id"
  put  :save,             "/binary/:id"
  post :create,           "/binary"

  before_request do |name, request|
    # Convert 'data' to base64, if it's present
    if(!request.post_params[:data].nil?)
      request.post_params[:data] = Base64.encode64(request.post_params[:data])
    end
  end

  def Binary.find(id)
    b = super(id)

    b.data = Base64.decode64(b.data)

    return b
  end
end

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

class Workspace < ActiveRestClient::Base
  base_url HOST
  request_body_type :json

  include ActiveRestExtras

  get  :all,    "/binary/:binary_id/workspaces"
  post :create, "/binary/:binary_id/create_workspace"
  get  :find,   "/workspace/:id"
  put  :save,   "/workspace/:id"

  def set(params)
    return post_stuff("/workspace/:id/set", params)
  end

  def get(params)
    result = get_stuff("/workspace/:id/get", params)

    return result.value
  end
end

class Memory < ActiveRestClient::Base
  base_url HOST
  request_body_type :json

  get  :all,    "/workspace/:workspace_id/memories"
  post :create, "/workspace/:workspace_id/create_memory"
  get  :find,   "/memory/:id"
  put  :save,   "/memory/:id"
end

x = Workspace.find(3)
puts(x.inspect)

puts x.set(:name => "abc", :value => "hihihi")

puts(x.get(:name => "abc"))
