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
      Typhoeus.get(domain + "/license", userpwd: key + ":").success?
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
