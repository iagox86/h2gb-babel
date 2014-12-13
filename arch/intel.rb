require 'metasm'
require 'arch/arch'

class Intel < Arch
  X86 = "x86"
  X64 = "x64"

  # Basically, these are instructions from which execution will never return
  MANDATORY_JUMPS = [ 'jmp' ]

  # Lines that don't carry on
  DOESNT_RETURN = [ 'ret', 'retn' ]

  # These are instructions that may or may not return
  OPTIONAL_JUMPS = [ "jo", "jno", "js", "jns", "je", "jz", "jne", "jnz", "jb", "jnae", "jc", "jnb", "jae", "jnc", "jbe", "jna", "ja", "jnbe", "jl", "jnge", "jge", "jnl", "jle", "jng", "jg", "jnle", "jp", "jpe", "jnp", "jpo", "jcxz", "jecxz" ]

  # Registers that affect the stack
  STACK_REGISTERS = [ 'esp', 'rsp' ]

  def get_stack_change(operator, operand1, operand2)
    if(operator == 'push')
      return -@wordsize / 8
    end

    if(operator == 'pop')
      return @wordsize / 8
    end

    if(operator == 'pusha')
      return -(((@wordsize / 8) / 2) * 8)
    end

    if(operator == 'popa')
      return (((@wordsize / 8) / 2) * 8)
    end

    if(operator == 'pushad')
      return -((@wordsize / 8) * 8)
    end

    if(operator == 'popad')
      return ((@wordsize / 8) * 8)
    end

    if(!operand1.nil? && operand1[:type] == 'register' && STACK_REGISTERS.index(operand1[:value]))
      if(!operand2.nil? && operand2[:type] == 'immediate')
        value = operand2[:value]
        if(operator == 'add')
          return value
        elsif(operator == 'sub')
          return -value
        end
      end
    end

    return 0
  end

  def initialize(data, cpu, base)
    @decoder = Metasm::EncodedData.new(data)

    if(cpu == X86)
      @cpu = Metasm::X86.new()
      @wordsize = 32
    elsif(cpu == X64)
      @cpu = Metasm::X64_64.new()
      @wordsize = 64
    else
      raise(Exception, "Unknown CPU: #{cpu}")
    end

    @base = base
  end

  def mandatory_jump?(i)
    return !(MANDATORY_JUMPS.index(i).nil?)
  end

  def optional_jump?(i)
    return !(OPTIONAL_JUMPS.index(i).nil?)
  end

  def doesnt_return?(i)
    return !(DOESNT_RETURN.index(i).nil?)
  end

  def disassemble(address)
    @decoder.ptr = address
    instruction = @cpu.decode_instruction(@decoder, @decoder.ptr + @base)

    if(instruction.nil?)
      return nil
    end

    operands = []
    instruction.instruction.args.each do |arg|
      if(arg.is_a?(Metasm::Expression))
        operands << {
          :type => 'immediate',
          :value => ("%s%s%s" % [arg.lexpr || '', arg.op || '', arg.rexpr || '']).to_i()
        }
      elsif(arg.is_a?(Metasm::Ia32::Reg))
        operands << {
          :type => 'register',
          :value => arg.to_s,
          :regsize => arg.sz,
          :regnum => arg.val,
        }
      elsif(arg.is_a?(Metasm::Ia32::ModRM))
        operands << {
          :type => 'memory',
          :value => arg.symbolic.to_s(),

          :segment         => arg.seg,
          :memsize         => arg.sz,
          :base_register   => arg.i.to_s(),
          :multiplier      => arg.s || 1,
          :offset          => arg.b.to_s(),
          :immediate       => arg.imm.nil? ? 0 : arg.imm.rexpr,
        }
      elsif(arg.is_a?(Metasm::Ia32::SegReg))
        operands << {
          :type => 'register',
          :value => arg.to_s()
        }
      elsif(arg.is_a?(Metasm::Ia32::FpReg))
        operands << {
          :type => "unknown[1]",
          :value => arg.to_s()
        }
      elsif(arg.is_a?(Metasm::Ia32::SimdReg))
        operands << {
          :type => 'register',
          :value => arg.to_s()
        }
      elsif(arg.is_a?(Metasm::Ia32::Farptr))
        operands << {
          :type => "farptr",
          :value => arg.to_s()
        }
      else
        puts("Unknown argument type:")
        puts(arg.class)
        puts(arg)

        raise(NotImplementedError)
      end
    end

    return {
      :address    => address,
      :type       => "instruction",
      :length     => instruction.bin_length,
      :value      => instruction.to_s,
      :details    => {
#        :stack_delta => (get_stack_change(instruction.instruction) || 0)
      },
      :references => do_refs(instruction.instruction.opname, operands),
    }
  end
end
