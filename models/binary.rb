# binary.rb
# Create on November 4, 2014
# By Ron Bowes

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


