require "typhoeus"
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
    RPW_SERVER_DOMAIN = ENV["RPW_SERVER_DOMAIN"] || "https://rpw-licensor.speedshop.co"

    def setup(key)
      gateway.authenticate_key(key)
      keyfile["key"] = key
    end

    def directory_setup
      ["videos", "quizzes", "labs", "text", "cgrp"].each do |path|
        FileUtils.mkdir_p(path) unless File.directory?(path)
      end

      client_data["test"] = "test" # just to write the file

      File.open(".gitignore", "a") do |f|
        f.puts "\n"
        f.puts ".rpw_key\n"
        f.puts ".rpw_info\n"
        f.puts "videos\n"
        f.puts "quizzes\n"
        f.puts "labs\n"
        f.puts "text\n"
        f.puts "cgrp\n"
      end
    end

    def next
      last_completed_position = (client_data["position"] + 1) || 0
      content = gateway.get_content_by_position(last_completed_position)
      download_content(content, folder: content["style"])
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

    def display_content(content)
      case content["style"]
      when "video"
        exec("open videos/#{content['s3_key']}.mp4")
      when "quiz"
        # start quiz routine
      when "lab"
        # extract and rm archive
        puts "Lab downloaded to labs/#{content['s3_key']}, navigate there and look at the README to continue"
      when "text"
        exec("`$EDITOR` text/#{content['s3_key']}")
      when "cgrp"
        # extract and rm archive
        puts "The Complete Guide to Rails Performance has been downloaded and extracted to the cgrp directory."
        puts "All source code for the CGRP is in the src directory, PDF and other compiled formats are in the release directory."
      end
    end

    def download_content(content, folder:)
      downloaded_file = File.open("#{folder}/#{content['s3_key']}")
      puts "Beginning download, please wait."
      request = Typhoeus::Request.new(content["url"])
      request.on_headers { |response| raise "Request failed" if response.code != 200 }
      request.on_body do |chunk|
        downloaded_file.write(chunk)
        printf(".")
      end
      request.on_complete { |response| downloaded_file.close }
      request.run
    end
  end

  require "fileutils"
  require "yaml"

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
    end

    private

    def data
      @data ||= begin
        yaml = begin
          YAML.safe_load(File.read(self.class::DOTFILE_NAME))
        rescue
          nil
        end
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
