$LOAD_PATH << File.dirname(__FILE__)

require 'json'
require 'httparty'
require 'arch/x86'

require 'pp' # debug

HOST = ARGV[0] || "http://localhost:9292"

def do_get(url)
  result = HTTParty.get(HOST + url)

  return JSON.parse(result.body, :symbolize_names => true)
end

def do_post(url, body = {})
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

def binary_create_workspace(binary_id)
  return do_post("/binary/%d/create_workspace" % binary_id)
end

def binary_workspaces(binary_id)
  return do_get("/binary/%d/workspaces" % binary_id)
end

def workspace_delete(id)
  return do_delete("/workspace/%d" % id)
end

def workspace_set(id, name, value)
  return do_post("/workspace/%d/set" % id, {:name => name, :value => value })
end

def workspace_set_multiple(id, values)
  return do_post("/workspace/%d/set" % id, values)
end

def workspace_get(id, name = nil)
  if(name.nil?())
    return do_get("/workspace/%d" % [id, name])
  else
    return do_get("/workspace/%d/get?name=%s" % [id, name])
  end
end

def workspace_create_memory(id)
  return do_post("/workspace/%d/create_memory" % id)
end

def memory_create_segment(id, name, address, file_address, data)
  return do_post("/memory/%d/create_segment" % id, { :segment => {
    :name         => name,
    :address      => address,
    :file_address => file_address,
    :data         => Base64.encode64(data),
  }})
end

def memory_create_node(id, address, type, length, value, details = {}, references = [])
  return do_post("/memory/%d/create_node" % id, { :node => {
    :address      => address,
    :type         => type,
    :length       => length,
    :value        => value,
    :details      => details,
    :references   => references,
  }})
end

def memory_get(id, starting = 0)
  return do_get("/memory/%d?starting=%d" % [id, starting])
end

def memory_segments(id, starting = 0)
  return do_get("/memory/%d/segments?starting=%d" % [id, starting])
end

def memory_nodes(id, starting = 0)
  return do_get("/memory/%d/nodes?starting=%d" % [id, starting])
end

def memory_delete(id)
  return do_delete("/memory/%d" % id)
end

def print_nodes(memory_id)
  memory = memory_get(memory_id)
  memory = memory[:memory]
  nodes = memory[:nodes]

  nodes.each do |overlay|
    node = overlay[:node]

    puts("0x%08x %s" % [node[:address], node[:value]])
  end
end

puts("Uploading a test binary")
binary = binary_upload("./sample.raw")
binary_id = binary[:binary_id]
puts("WORKSPACE ID: %d" % binary_id)

puts("Listing binaries (we should see the one):")
pp(binary_list())

puts("Downloading it:")
download = binary_download(binary_id)
pp(download)

puts("Creating a workspace:")
workspace = binary_create_workspace(binary_id)
workspace_id = workspace[:workspace_id]
pp(workspace)
puts("WORKSPACE ID: %d" % workspace_id)

puts("Listing workspaces:")
pp binary_workspaces(binary_id)

puts("Setting some variables")
pp workspace_set(workspace_id, "key1", "value1")
pp workspace_set_multiple(workspace_id, [
  {:name => "key2", :value => 0x1234},
  {:name => "key3", :value => [1, 2, 3]},
  {:name => "key4", :value => {:a => 'b', :c => 'd'}},
])

puts("Retrieving those variables")
pp workspace_get(workspace_id, "key1")
pp workspace_get(workspace_id, "key2")
pp workspace_get(workspace_id, "key3")
pp workspace_get(workspace_id, "key4")

puts("Retrieving all variables")
pp workspace_get(workspace_id)

puts("Creating memory abstraction")
memory = workspace_create_memory(workspace_id)
memory_id = memory[:memory_id]
pp memory

puts("Creating a naive segment (mapping the whole file to offset 0)")
memory_create_segment(memory_id, ".raw", 0, 0, download[:data])
#
#puts("Creating a bunch of one-byte nodes")
#0.upto(download[:data].length() - 1) do |i|
#  puts("Creating byte number #{i}...")
#  pp memory_create_node(memory_id, i, 'byte', 1, "db 0x%02x" % download[:data][i].ord)
#  puts()
#end
#
#puts("Creating some two-byte nodes")
#0.step(download[:data].length() - 1, 4) do |i|
#  puts("Creating word number #{i}...")
#  pp memory_create_node(memory_id, i, 'word', 2, "dw 0x%04x" % download[:data][i, 2].unpack("S"))
#  puts()
#end
#
#puts("Creating a couple four-byte nodes")
#0.step(download[:data].length() - 1, 8) do |i|
#  puts("Creating dword number #{i}...")
#  pp memory_create_node(memory_id, i, 'word', 4, "dd 0x%08x" % download[:data][i, 4].unpack("I"))
#  puts()
#end
#
#puts("Creating a few byte nodes")
#0.upto(8) do |i|
#  puts("Creating byte number #{i}...")
#  pp memory_create_node(memory_id, i, 'byte', 1, "db 0x%02x" % download[:data][i].ord)
#  puts()
#end

test = X86.new(download[:data])
disassembly = test.disassemble(0)
pp disassembly

i = 0
while(i < disassembly.length()) do
  inst = disassembly[i]
  pp memory_create_node(memory_id, inst[:offset], 'instruction', inst[:raw].length, "%s %s" % [inst[:operator], (inst[:operands].map() do |o| (o[:value].is_a?(Fixnum) ? '0x%x' % o[:value] : o[:value]); end).join(", ")])
  i += (inst[:raw].length == 0 ? 1 : inst[:raw].length)
end

print_nodes(memory_id)

puts("Deleting the memory")
pp memory_delete(memory_id)

puts("Deleting the workspace")
pp workspace_delete(workspace_id)

puts("Deleting the binary")
pp binary_delete(binary_id)

puts("Listing binaries (this should be empty):")
pp(binary_list())

puts("Deleting everything, just to be safe")
pp(binary_delete_all())

