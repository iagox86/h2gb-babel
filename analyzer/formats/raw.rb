require 'base64'
require 'metasm'

class Raw
  def Raw.parse(data)
    size = data.length

    out = { }

    # Header
    out[:header] = {
      :format       => "RAW",
      :base         => 0,
      :entrypoint   => 0,
    }

    # Segments
    out[:segments] = [{
      :name         => ".raw",
      :address      => 0,
      :file_address => 0,
      :file_size    => size,
      :data         => data,
    }]

    return out
  end
end

