require 'base64'
require 'metasm'

class ELF
  def ELF.parse(data)
    elf = { }

    e = Metasm::ELF.decode_file(self.filename)

    # Header
    elf[:header] = {
      :format     => "ELF",
      :entrypoint => e.header.entry,
    }

    # Segments
#    elf[:segments] = []
#    e.segments.each do |s|
#      segment = {
#        :type   => s.type,
#        :offset => s.offset,
#        :vaddr  => s.vaddr,
#        :size   => s.filesz,
#        :flags  => s.flags,
#        :align  => s.align,
#      }
#
#      elf[:segments] << segment
#    end

    # Segments
    elf[:segments] = []
    e.segments.each do |s|
      segment = {
        :name        => s.name,
        :addr        => s.addr,
        :flags       => s.flags,
        :file_offset => s.offset,
        :file_size   => s.size,
        :data        => data[s.offset, s.size],
      }

      elf[:segments] << segment
    end

#    elf[:symbols] = []
#    e.symbols.each do |s|
#      symbol = {
#        :name =>   s.name,
#        :type =>   s.type,
#        :offset => s.value,
#        :size =>   s.size,
#      }
#
#      elf[:symbols] << symbol
#    end

    return elf
  end
end
