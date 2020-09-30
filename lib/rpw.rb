module RPW
  VERSION = "0.0.1"

  class Gateway
    class Error < StandardError; end

    def authenticate_key(key)
    end

    def get_resource(resource)
    end
  end

  class Client
    DOTFILE_NAME = ".rpw_key"
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
      @gateway ||= Gateway.new
    end
  end
end
