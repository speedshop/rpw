require "typhoeus"
require "base64"

module RPW
  class Gateway
    attr_accessor :domain 

    def initialize(domain)
      @domain = domain
    end

    class Error < StandardError; end

    def authenticate_key(key)
      request = Typhoeus::Request.new(
        domain + "/license",
        method: :get,
        headers: { Authorization: "Basic #{Base64.encode64(key + ':')}" }
      )
      
      request.on_complete do |response|
        if response.success?
          true
        else
          raise Error, "Server responded: #{response.code} #{response.response_body}"
        end
      end

      request.run
    end

    def get_resource(resource)
    end
  end

  class Client
    DOTFILE_NAME = ".rpw_key"
    RPW_SERVER_DOMAIN = "https://rpw-licensor.speedshop.co"

    class Error < StandardError; end

    def setup(key)
      # authenticate against server
      gateway.authenticate_key(key)

      # write authenticated key
      begin
        File.open(DOTFILE_NAME, "w") { |f| f.write(key) }
      rescue
        raise Error.new "Could not create dotfile in this directory \
                         to save your key. Check your file permissions."
      end

      key
    end

    private

    def gateway
      @gateway ||= Gateway.new(RPW_SERVER_DOMAIN)
    end
  end
end
