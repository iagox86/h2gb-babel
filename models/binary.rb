# binary.rb
# Create on November 4, 2014
# By Ron Bowes

require 'models/model'

class Binary < Model
  def initialize(params = {})
    super(params)
  end

  def after_request()
    # Handle the simple case (receiving one binary)
    if(@o[:data])
      @o[:data] = Base64.decode64(@o[:data])
    end

    # Handle the complicated case (receiving a bunch of binaries)
    if(@o[:binaries])
      @o[:binaries].map do |binary|
        if(binary[:data])
          binary[:data] = Base64.decode64(binary[:data])
        end

        binary # return
      end
    end
  end

  def Binary.find(id, params = {})
    return get_stuff(Binary, '/binaries/:binary_id', params.merge({ :binary_id => id }))
  end

  def Binary.create(params)
    # Automatically encode as base64
    params[:data] = Base64.encode64(params[:data])

    return post_stuff(Binary, '/binaries', params)
  end

  def Binary.all(params = {})
    return get_stuff(Binary, '/binaries', params)
  end

  def save(params = {})
    return put_stuff('/binaries/:binary_id', params.merge(self.o))
  end

  def delete(params = {})
    return delete_stuff('/binaries/:binary_id', params.merge({:binary_id => self.o[:binary_id]}))
  end
end
