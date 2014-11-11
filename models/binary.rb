# binary.rb
# Create on November 4, 2014
# By Ron Bowes

require 'models/model'

class Binary < Model
  def initialize(params = {})
    super(params)
  end

  def Binary.find(id, params = {})
    return get_stuff(Binary, '/binaries/:binary_id', params.merge({ :binary_id => id }))
  end

  def Binary.create(params)
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
