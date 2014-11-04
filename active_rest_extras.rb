# active_rest_extras.rb
# Create on November 4, 2014
# By Ron Bowes

require 'active_rest_client'
#require 'cgi' # for URI::encode()

module ActiveRestExtras
  # This ugly function takes a URL such as /test/:id/:id2 and replaces the :id and :id2
  # values based first on the 'params' hash passed in, then from attributes of the class.
  def format_url(url, params = {})
    params.each_pair do |k, v|
      if(!url.index(":#{k}").nil?)
        url = url.gsub(/:#{k.to_s()}([^a-zA-Z0-9_.-]|$)/, params.delete(k).to_s + '\\1')
      end
    end

    @attributes.each_pair do |k, v|
      url = url.gsub(/:#{k}([^a-zA-Z0-9_.-]|$)/, v.to_s + '\\1')
    end

    return url
  end

  def post_stuff(url, params = {})
    url = format_url(url, params)

    return Workspace._request(HOST + url, :post, params)
  end

  def get_stuff(url, params = {})
    url = format_url(url, params) + "?"

    params.each_pair do |k, v|
      url += params.to_query()
    end

    return Workspace._request(HOST + url, :get)
  end

  def delete_stuff(url, params = {})
    url = format_url(url, params) + "?"

    params.each_pair do |k, v|
      url += params.to_query()
    end

    return Workspace._request(HOST + url, :delete)
  end
end
