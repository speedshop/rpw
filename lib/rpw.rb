require "typhoeus"
require "base64"
require "fileutils"
require "yaml"
require "json"

module RPW
  class Error < StandardError; end

  class Gateway
    attr_accessor :domain

    def initialize(domain, key)
      @domain = domain
      @key = key
    end

    class Error < StandardError; end

    def authenticate_key(key)
      Typhoeus.get(domain + "/license", userpwd: key + ":").success?
    end

    def get_content_by_position(position)
      response = Typhoeus.get(domain + "/content/position/?position=" + position, userpwd: key + ":")
      if response.success? 
        JSON.parse(response.body)
      else 
        raise Error, "There was a problem fetching this content."
      end
    end
  end

  class Client
    RPW_SERVER_DOMAIN = "https://rpw-licensor.speedshop.co"

    def setup(key)
      gateway.authenticate_key(key)
      keyfile["key"] = key
    end

    def directory_setup
      ["videos", "quizzes", "labs"].each do |path|
        FileUtils.mkdir_p(path) unless File.directory?(path)
      end

      File.open('.gitignore', 'a') do |f| 
        f.puts "\n"
        f.puts ".rpw_key\n"
        f.puts ".rpw_info\n"
        f.puts "videos\n"
        f.puts "quizzes\n"
        f.puts "labs\n"
      end
    end

    def next
      last_completed_position = (client_data["position"] + 1) || 0
      content = gateway.get_content_by_position(last_completed_position)
      display_content(content)
    end

    private

    def client_data
      @client_data ||= ClientData.new
    end

    def keyfile 
      @keyfile ||= Keyfile.new
    end

    def gateway
      @gateway ||= Gateway.new(RPW_SERVER_DOMAIN, keyfile["key"])
    end

    def display_content 
      case content["type"]
      when "video"
        # download 
        # play video with preferred player 
      when "quiz"
        # start quiz routine 
      when "lab"
        # download lab
        # display message
      end
    end
  end

  class ClientData 
    DOTFILE_NAME = ".rpw_info"

    def [](key)
      make_sure_dotfile_exists
      data[key]
    end

    def []=(key, value)
      data[key] = value
      begin
        File.open(self.class::DOTFILE_NAME, "w") { |f| f.write(YAML.dump(data)) }
      rescue
        raise Error, "The RPW data file in this directory is not writable. \
                      Check your file permissions."
      end
      value
    end

    private

    def data 
      @data ||= begin
        yaml = YAML.safe_load(File.read(self.class::DOTFILE_NAME)) rescue nil
        yaml || {}
      end
    end

    def make_sure_dotfile_exists
      return true if File.exist?(self.class::DOTFILE_NAME)
      begin
        FileUtils.touch(self.class::DOTFILE_NAME)
      rescue
        raise Error, "Could not create the RPW data file in this directory \
                      Check your file permissions."
      end
    end
  end

  class Keyfile < ClientData 
    DOTFILE_NAME = ".rpw_key"
  end
end
