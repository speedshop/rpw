require "typhoeus"
require "base64"
require 'fileutils'
require "yaml"

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
      gateway.authenticate_key(key)
      client_data_set "key", key
      client_data["key"] 
    end

    def next
      last_completed_position
      gateway.content_get(last_completed_position)
    end

    private

    def client_data
      make_sure_dotfile_exists
      data = YAML.load(File.read(DOTFILE_NAME)) rescue nil
      data ||= {}
    end

    def client_data_set(key, value)
      data = client_data
      data[key] = value
      File.open(DOTFILE_NAME, "w") { |f| f.write(YAML.dump(data))}
      data
    end

    def gateway
      @gateway ||= Gateway.new(RPW_SERVER_DOMAIN)
    end

    def make_sure_dotfile_exists
      return true if File.exist?(DOTFILE_NAME)
      begin 
        FileUtils.touch(DOTFILE_NAME)
      rescue
        raise Error.new "Could not create the RPW data file in this directory \
                         Check your file permissions."
      end
    end
  end
end
