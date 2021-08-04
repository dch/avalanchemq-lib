##
# Middleware for protecting unsafe HTTP requests when value of Origin HTTP request header doesn't match default or whitelisted URIs.
# http://en.wikipedia.org/wiki/Cross-site_request_forgery
# http://tools.ietf.org/html/draft-abarth-origin
#
# === Options:
#
#   :whitelist  Array of allowed URIs. Defaults to []
#
# === Examples:
#
#  HTTP::Protection::Origin.new(whitelist: ["http://friend.com"])
#
module HTTP::Protection
  class Origin
    include Base
    include HTTP::Handler

    DEFAULT_PORTS = {
      "http"  => 80,
      "https" => 443,
    }

    def initialize(@whitelist : Array(String) = [] of String)
    end

    def call(context : HTTP::Server::Context)
      return call_next(context) if accepts?(context)

      logger.warn { "origin '#{origin(context)}' unauthorized" }

      forbidden(context)
    end

    private def accepts?(context)
      origin_fallback = origin(context)

      return true if safe?(context)
      return true if @whitelist.includes?(origin_fallback)
      return true if base_url(origin_fallback) == origin_fallback
      return true unless origin_fallback
    end

    private def base_url(origin)
      uri = URI.parse(origin.to_s)

      port = ""
      port = ":#{uri.port}" unless uri.port == DEFAULT_PORTS[uri.scheme]

      "#{uri.scheme}://#{uri.host}#{port}"
    rescue
      nil
    end
  end
end
