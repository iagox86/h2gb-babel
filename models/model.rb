# model.rb
# Created on November 11, 2014
# By Ron Bowes

require 'httparty'
require 'uri'

class Model
  include HTTParty

  attr_accessor :o

  def initialize(o = {})
    @o = o
  end

  def Model.format_url(url, params = {})
    params.each_pair do |k, v|
      if(!url.index(":#{k}").nil?)
        url = url.gsub(/:#{k.to_s()}([^a-zA-Z0-9_.-]|$)/, params.delete(k).to_s + '\\1')
      end
    end

    return HOST + url
  end

  def Model.do_request(cls, method, url, use_body, params = {})
    # TODO: Before hooks
#    if(self.respond_to?(:before_request))
#      params = before_request(params)
#    end

    # Replace placeholders in the URL with the params field
    url = format_url(url, params)

    if(use_body)
      result = method.call(url, :body => JSON.pretty_generate(params))
    else
      new_params = []
      params.each_pair do |k, v|
        new_params << "%s=%s" % [URI::encode(k.to_s()), URI::encode(v.to_s())]
      end

      url = url + "?" + new_params.join('&')

      result = method.call(url)
    end

    if(result.response.code.to_i != 200)
      raise(Exception, "HTTP Request failed for #{url}: #{result.response.to_s}")
    end

    # Parse out the data
    result = JSON.parse(result.response.body, :symbolize_names => true)

    # Create a new class with the result
    instance = cls.new(result)

    # Run 'after' hooks
    if(instance.respond_to?(:after_request))
      instance.after_request()
    end

    return instance
  end

  def Model.get_stuff(cls, url, params = {})
    return Model.do_request(cls, self.method(:get), url, false, params)
  end
  def get_stuff(url, params = {})
    return Model.get_stuff(self.class, url, params)
  end

  def Model.post_stuff(cls, url, params = {})
    return Model.do_request(cls, self.method(:post), url, true, params)
  end
  def post_stuff(url, params = {})
    return Model.post_stuff(self.class, url, params)
  end

  def Model.put_stuff(cls, url, params = {})
    return Model.do_request(cls, self.method(:put), url, true, params)
  end

  def put_stuff(url, params = {})
    return Model.put_stuff(self.class, url, params.merge(@o))
  end

  def Model.delete_stuff(cls, url, params = {})
    return Model.do_request(cls, self.method(:delete), url, false, params)
  end

  def delete_stuff(url, params = {})
    return Model.delete_stuff(self.class, url, params)
  end
end
