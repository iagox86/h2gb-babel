require 'metasm'

class Arch
  attr_reader :instructions

  def initialize(data)
    @data = data
  end

  def disassemble()
    raise NotImplementedError
  end

  # wordsize, in bits
  def wordsize()
    raise NotImplementedError
  end
  def mandatory_jump?(i)
    raise NotImplementedError
  end
  def optional_jump?(i)
    raise NotImplementedError
  end
  def doesnt_return?(i)
    raise NotImplementedError
  end
  def jump?(i)
    return mandatory_jump?(i) || optional_jump?(i)
  end
  def returns?(i)
    return !mandatory_jump?(i) && !doesnt_return?(i)
  end

  # TODO: This needs to go at a higher level, it doesn't belong in the disassembler
  def do_refs(address, length, operator, operands)
    refs = []

    # If it's not a mandatory jump, it references the next address
    if(returns?(operator))
      refs << (address + length)
    end

    # If it's a jump of any kind (with an immediate destination), fill in the ref
    if((jump?(operator)) && operands[0] && operands[0][:type] == 'immediate')
      refs << operands[0][:value]
    end

    return refs
  end
end
