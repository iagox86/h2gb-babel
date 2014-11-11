# binary.rb
# Create on November 4, 2014
# By Ron Bowes

require 'models/model'

class NuBinary < Model
  def initialize(params = {})
    super(params)
  end

  def NuBinary.find(id, params = {})
    return get_stuff(NuBinary, '/binaries/:binary_id', params.merge({ :binary_id => id }))
  end

  def NuBinary.create(params)
    return post_stuff(NuBinary, '/binaries', params)
  end

  def NuBinary.all(params = {})
    return get_stuff(NuBinary, '/binaries', params)
  end

  def save(params = {})
    return put_stuff('/binaries/:binary_id', params.merge(self.o))
  end

  def delete(params = {})
    return delete_stuff('/binaries/:binary_id', params.merge({:binary_id => self.o[:binary_id]}))
  end
end
