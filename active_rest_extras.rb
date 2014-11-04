# active_rest_extras.rb
# Create on November 4, 2014
# By Ron Bowes

require 'active_rest_client'
#require 'cgi' # for URI::encode()

module ActiveRestExtras
  def format_url(url, params)
    @attributes.each_pair do |k, v|
      url = url.gsub(":#{k}", v.to_s)
    end

    params.each_pair do |k, v|
      if(!url.index(":#{k}").nil?)
        url = url.gsub(":#{k}", params.delete(k))
      end
    end

    return url
  end

  def post_stuff(url, params)
    url = format_url(url, params)

    return Workspace._request(HOST + url, :post, params)
  end

  def get_stuff(url, params)
    url = format_url(url, params) + "?"

    params.each_pair do |k, v|
      url += params.to_query()
    end

    return Workspace._request(HOST + url, :get)
  end
end

