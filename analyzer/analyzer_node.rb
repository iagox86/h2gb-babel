# analyzer_node.rb
# By Ron Bowes
# Created December 22, 2014

class AnalyzerNode
  attr_reader :address, :length
  attr_reader :dirty

  def initialize(address, type, length, value, refs, dirty = true)
    @address = address
    @type    = type
    @length  = length
    @value   = value
    @refs    = refs

    @dirty = dirty
  end

  def dirty?()
    return @dirty
  end

  def to_json(cleanup = false)
    if(cleanup)
      @dirty = false
    end

    return {
      :address => @address,
      :type    => @type,
      :length  => @length,
      :value   => @value,
      :refs    => @refs,
    }
  end
end
