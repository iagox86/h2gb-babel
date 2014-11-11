# model.rb
# Created on November 11, 2014
# By Ron Bowes

require 'httparty'
require 'pp' # TODO: Debug

HOST = "http://localhost:9292"

class Model
  include HTTParty

  attr_accessor :o

  def initialize(o = {})
    @o = o
  end

  def Model.handle_response(response)
    return self.new(response.parsed_response)
  end

  def Model.format_url(url, params = {})
    params.each_pair do |k, v|
      if(!url.index(":#{k}").nil?)
        url = url.gsub(/:#{k.to_s()}([^a-zA-Z0-9_.-]|$)/, params.delete(k).to_s + '\\1')
      end
    end

    return HOST + url
  end

  def Model.do_request(method, url, use_body, params = {})
    # TODO: Before hooks
#    if(self.respond_to?(:before_request))
#      params = before_request(params)
#    end

    # Replace placeholders in the URL with the params field
    url = format_url(url, params)

    if(use_body)
      result = method.call(url, :body => JSON.pretty_generate(params))
    else
      # TODO
      raise(NotImplementedError, "TODO")
    end

    # TODO: Check return status

    result = JSON.parse(result.response.body, :symbolize_names => true)

    # TODO: After hooks

    return self.new(result)
  end

  def Model.get_stuff(url, params = {})
    url = format_url(url, params)

    return self.class.new(HTTParty.get(url).parsed_response())
  end

  def get_stuff(url, params = {})
    return Model.get_stuff(url, params.merge(@o))
  end

  def Model.post_stuff(url, params = {})
    return Model.do_request(self.method(:post), url, true, params)
  end

  def post_stuff(url, params = {})
    return Model.post_stuff(url, params.merge(@o))
  end

  def Model.put_stuff(url, params = {})
    url = format_url(url, params)
    return self.class.new(HTTParty.put(url).parsed_response(), :body => params)
  end

  def put_stuff(url, params = {})
    return Model.put_stuff(url, params.merge(@o))
  end

  def Model.delete_stuff(url, params = {})
    url = format_url(url, params)
    return self.class.new(HTTParty.delete(url).parsed_response())
  end

  def delete_stuff(url, params = {})
    return Model.delete_stuff(url, params.merge(@o))
  end
end
