$LOAD_PATH << File.dirname(__FILE__)

require 'json'
require 'httparty'

require 'pp' # debug

HOST = ARGV[0] || "http://localhost:9292"

def do_get(url)
  result = HTTParty.get(HOST + url)

  return JSON.parse(result.body, :symbolize_names => true)
end

def do_post(url, body)
  result = HTTParty.post(HOST + url,
    :body => JSON.generate(body),
    :headers => {
      'Content-Type' => 'application/json',
    }
  )

  return JSON.parse(result.body, :symbolize_names => true)
end

def do_delete(url)
  result = HTTParty.delete(HOST + url)

  return JSON.parse(result.body, :symbolize_names => true)
end

def binary_upload(filename)
  name = File.basename(filename)
  comment = "Uploaded by h2gb-babel"

  return do_post("/binary/upload", {
                  :name => name,
                  :comment => comment,
                  :data => Base64.encode64(IO.read(filename)),
                })
end

def binary_list()
  return do_get("/binaries")[:binaries]
end

def binary_delete(id)
  return do_delete("/binary/%d" % id)
end

def binary_delete_all()
  binaries = binary_list()

  puts(binaries.inspect)

  binaries.each do |b|
    binary_delete(b[:id])
  end
end

def binary_download(binary_id)
  result = do_get("/binary/%d/download" % binary_id)
  result[:data] = Base64.decode64(result[:data])
  return result
end

puts("Uploading a test binary")
binary = binary_upload("./sample.raw")
binary_id = binary[:binary_id]
puts("ID: %d" % binary_id)

puts("Listing binaries (we should see the one):")
puts(binary_list())

puts("Downloading it:")
download = binary_download(binary_id)
puts(download)
f = File.new("test.out", "wb")
f.write(download[:data])
f.close()

puts("Deleting it")
binary_delete(binary_id)

puts("Listing binaries (this should be empty):")
puts(binary_list())
