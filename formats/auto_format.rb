# auto_format.rb
# By Ron Bowes
# Created 2014-12-12

require 'formats/elf'
require 'formats/pe'
require 'formats/raw'

class AutoFormat
  def AutoFormat.parse(data)
    if(data =~ /^MZ/)
      # PE
      return PE.parse(data)
    elsif(data =~ /^ELF/)
      # ELF
      return ELF.parse(data)
    else
      # Raw
      return Raw.parse(data)
    end
  end
end
