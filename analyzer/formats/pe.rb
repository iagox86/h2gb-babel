require 'base64'
require 'metasm'

require 'tempfile'

class PE
  def PE.parse(data)
    pe = { }

    # TODO: This is balls
    begin
      file = Tempfile.new('h2gb')
      file.write(data)
      file.rewind
      e = Metasm::PE.decode_file(file.path)
    ensure
      file.unlink
    end

    # Header
    pe[:header] = {
      :format       => "PE",
      :base         => e.optheader.image_base,
      :sect_align   => e.optheader.sect_align,
      :code_size    => e.optheader.code_size,
      :data_size    => e.optheader.data_size,
      :entrypoint   => e.optheader.entrypoint,
      :base_of_code => e.optheader.base_of_code,
    }

    # Sections
    pe[:segments] = []
    e.sections.each do |s|
      segment = {
        :name         => s.name,
        :address      => s.virtaddr,
        :flags        => s.characteristics,
        :file_address => s.rawaddr,
        :file_size    => s.rawsize,
        :data         => data[s.rawaddr, s.rawsize],
      }

      pe[:segments] << segment
    end

#    pe[:imports] = {}
#    e.imports.each do |import_directory|
#      pe[:imports][import_directory.libname] = []
#      import_directory.imports.each do |import|
#        pe[:imports][import_directory.libname] << {
#          :name   => import.name,
#          :hint   => import.hint,
#          :target => import.target,
#        }
#      end
#    end
#
#    pe[:exports] = []
#
#    if(!e.export.nil?)
#      e.export.exports.each do |export|
#        pe[:exports] << {
#          :ordinal        => export.ordinal,
#          :forwarder_lib  => export.forwarder_lib,
#          :forwarder_name => export.forwarder_name,
#          :name           => export.name,
#          :address        => export.target_rva,
#        }
#      end
#    end

    return pe
  end
end
