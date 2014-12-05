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
    params = params.merge(self.o)
    # TODO: Write a test for saving new data
    if(!params[:data].nil?)
      params[:data] = Base64.encode64(params[:data])
    end
    return put_stuff('/binaries/:binary_id', params.merge(self.o))
  end

  def delete(params = {})
    return delete_stuff('/binaries/:binary_id', params.merge({:binary_id => self.o[:binary_id]}))
  end

  def set_properties(hash, params = {})
    if(!hash.is_a?(Hash))
      raise(Exception, "set_properties() requires a hash")
    end

    return post_stuff('/binaries/:binary_id/set_properties', {
      :binary_id  => self.o[:binary_id],
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

    result = post_stuff('/binaries/:binary_id/get_properties', {
      :binary_id => self.o[:binary_id],
      :keys      => keys,
    }.merge(params))

    return result.o
  end

  def get_property(key, params = {})
    return get_properties([key], params)[key]
  end
end
