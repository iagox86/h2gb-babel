# binary.rb
# Create on November 4, 2014
# By Ron Bowes

require 'models/model'

class NuBinary < Model
  def initialize(params = {})
    super(params)
  end

  def NuBinary.find(id)
    return get_stuff('/binaries/:binary_id', { :binary_id => id })
  end

  def NuBinary.create(params)
    return post_stuff('/binaries', params)
  end

  def NuBinary.all(params = {})
    return get_stuff('/binaries', params)
  end
end


