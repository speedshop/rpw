require "typhoeus"
require "json"
require_relative "rpw/version" 

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
      response = Typhoeus.get(domain + "/contents/positional?position=#{position}", userpwd: @key + ":")
      if response.success?
        JSON.parse(response.body)
      else
        puts response.inspect
        raise Error, "There was a problem fetching this content."
      end
    end

    def list_content
      response = Typhoeus.get(domain + "/contents", userpwd: @key + ":")
      if response.success?
        JSON.parse(response.body)
      else
        puts response.inspect
        raise Error, "There was a problem fetching this content."
      end
    end

    def download_content(content, folder:)
      puts "Downloading #{content["title"]}..."
      downloaded_file = File.open("#{folder}/#{content["s3_key"]}", "w")
      request = Typhoeus::Request.new(content["url"])
      request.on_body do |chunk|
        downloaded_file.write(chunk)
        printf(".") if rand(500) == 0 # lol
      end
      request.on_complete { |response| downloaded_file.close }
      request
    end

    def latest_version?
      resp = Typhoeus.get("https://rubygems.org/api/v1/gems/rpw.json")
      data = JSON.parse resp.body 
      Gem::Version.new(RPW::VERSION) >= Gem::Version.new(data["version"])
    end
  end

  class Client
    RPW_SERVER_DOMAIN = ENV["RPW_SERVER_DOMAIN"] || "https://rpw-licensor.speedshop.co"

    def setup(key)
      gateway.authenticate_key(key)
      keyfile["key"] = key
    end

    def directory_setup
      ["video", "quiz", "lab", "text", "cgrp"].each do |path|
        FileUtils.mkdir_p(path) unless File.directory?(path)
      end

      client_data["completed"] = [] # just to write the file

      unless File.exist?(".gitignore") && File.read(".gitignore").match(/rpw_key/)
        File.open(".gitignore", "a") do |f|
          f.puts "\n"
          f.puts ".rpw_key\n"
          f.puts ".rpw_info\n"
          f.puts "video\n"
          f.puts "quiz\n"
          f.puts "lab\n"
          f.puts "text\n"
          f.puts "cgrp\n"
        end
      end
    end

    def next(open_after = false)
      complete
      content = next_content
      unless File.exist?(content["style"] + "/" + content["s3_key"])
        gateway.download_content(content, folder: content["style"]).run
        extract_content(content) if content["s3_key"].end_with?(".tar.gz")
      end
      client_data["current_lesson"] = content["position"]
      display_content(content, open_after)
    end

    def complete
      reset_progress unless client_data["current_lesson"] && client_data["completed"]
      client_data["completed"] ||= []
      client_data["completed"] += [client_data["current_lesson"] || 0]
    end

    def list
      gateway.list_content
    end

    def show(content_pos, open_after = false)
      content_pos = client_data["current_lesson"] if content_pos == :current
      content = gateway.get_content_by_position(content_pos)
      unless File.exist?(content["style"] + "/" + content["s3_key"])
        gateway.download_content(content, folder: content["style"]).run
        extract_content(content) if content["s3_key"].end_with?(".tar.gz")
      end
      client_data["current_lesson"] = content["position"]
      display_content(content, open_after)
    end

    def download(content_pos)
      if content_pos.downcase == "all"
        to_download = gateway.list_content
        hydra = Typhoeus::Hydra.new(max_concurrency: 5)
        to_download.each do |content|
          unless File.exist?(content["style"] + "/" + content["s3_key"])
            hydra.queue gateway.download_content(content, folder: content["style"])
          end
        end
        hydra.run
        to_download.each { |content| extract_content(content) if content["s3_key"].end_with?(".tar.gz") }
      else
        content = gateway.get_content_by_position(content_pos)
        unless File.exist?(content["style"] + "/" + content["s3_key"])
          gateway.download_content(content, folder: content["style"]).run
          extract_content(content) if content["s3_key"].end_with?(".tar.gz")
        end
      end
    end

    def progress
      contents = gateway.list_content
      {
        completed: client_data["completed"].size,
        total: contents.size,
        current_lesson: contents.find { |c| c["position"] == client_data["current_lesson"] },
        sections: chart_section_progress(contentsi)
      }
    end

    def set_progress(lesson)
      client_data["current_lesson"] = lesson.to_i
    end

    def reset_progress
      client_data["current_lesson"] = 0
      client_data["completed"] = []
    end

    def latest_version?
      if client_data["last_version_check"]
        return true if client_data["last_version_check"] >= Time.now - (60 * 60 * 24) 
        return false if client_data["last_version_check"] == false 
      end 

      begin 
        latest = gateway.latest_version?
      rescue 
        return true 
      end 

      if latest
        client_data["last_version_check"] = Time.now
      else 
        client_data["last_version_check"] = false 
      end
    end

    def setup?
      keyfile["key"]
    end

    private

    def chart_section_progress(contents)
      contents.group_by { |c| c["position"] / 100 }
        .each_with_object([]) do |(_, c), memo|
          completed_str = c.map { |l|
            if l["position"] == client_data["current_lesson"]
              "O"
            elsif client_data["completed"].include?(l["position"])
              "X"
            else
              "."
            end
          }.join
          memo << {
            title: c[0]["title"],
            progress: completed_str
          }
        end
    end

    def next_content
      contents = gateway.list_content
      return contents.first unless client_data["completed"]
      contents.delete_if { |c| client_data["completed"].include? c["position"] }
      contents.min_by { |c| c["position"] }
    end

    def client_data
      @client_data ||= ClientData.new
    end

    def keyfile
      @keyfile ||= Keyfile.new
    end

    def gateway
      @gateway ||= Gateway.new(RPW_SERVER_DOMAIN, keyfile["key"])
    end

    def extract_content(content)
      folder = content["style"]
      `tar -C #{folder} -xvzf #{folder}/#{content["s3_key"]}`
    end

    def display_content(content, open_after)
      puts "Viewing: #{content["title"]}"
      case content["style"]
      when "video"
        location = "video/#{content["s3_key"]}"
      when "quiz"
        Quiz.start(["give_quiz", "quiz/" + content["s3_key"]])
      when "lab"
        location = "lab/#{content["s3_key"]}"
      when "text"
        location = "lab/#{content["s3_key"]}"
      when "cgrp"
        puts "The Complete Guide to Rails Performance has been downloaded and extracted to the ./cgrp directory."
        puts "All source code for the CGRP is in the src directory, PDF and other compiled formats are in the release directory."
      end
      if location
        puts "Downloaded to #{location}"
        if open_after
          exec "#{open_command} #{location}"
        end
      end
    end

    require "rbconfig"
    def open_command
      host_os = RbConfig::CONFIG['host_os']
      case host_os
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        "start"
      when /darwin|mac os/
        "open"
      else 
        "xdg-open"
      end
    end
  end

  require "fileutils"
  require "yaml"

  class ClientData
    DOTFILE_NAME = ".rpw_info"

    def initialize
      make_sure_dotfile_exists
      data # access file to load
    end

    def [](key)
      data[key]
    end

    def []=(key, value)
      data
      data[key] = value

      begin
        File.open(filestore_location, "w") { |f| f.write(YAML.dump(data)) }
      rescue
        raise Error, "The RPW data at #{filestore_location} is not writable. \
                      Check your file permissions."
      end
    end

    def self.delete_filestore
      return unless File.exist?(filestore_location)
      FileUtils.remove(filestore_location)
    end

    def self.filestore_location
      File.expand_path("~/.rpw/" + self::DOTFILE_NAME)
    end

    private

    def filestore_location
      self.class.filestore_location
    end

    def create_client_data_directory(path)
      dirname = File.dirname(path)
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    end

    def data
      @data ||= begin 
        yaml = YAML.safe_load(File.read(filestore_location), permitted_classes: [Time]) rescue nil 
        yaml || {}
      end
    end

    def make_sure_dotfile_exists
      return true if File.exist?(filestore_location)
      create_client_data_directory(filestore_location)
      begin
        FileUtils.touch(filestore_location)
      rescue
        raise Error, "Could not create the RPW data file at ~/.rpw/ \
                      Check your file permissions."
      end
    end
  end

  class Keyfile < ClientData
    DOTFILE_NAME = ".rpw_key"
  end

  require "digest"
  require "thor"

  class Quiz < Thor
    desc "give_quiz FILENAME", ""
    def give_quiz(filename)
      @quiz_data = YAML.safe_load(File.read(filename))
      binding.irb
      @quiz_data["questions"].each { |q| question(q) }
    end

    private

    def question(data)
      puts data["prompt"]
      data["answer_choices"].each { |ac| puts ac }
      provided_answer = ask("Your answer?")
      answer_digest = Digest::MD5.hexdigest(data["prompt"] + provided_answer.upcase)
      if answer_digest == data["answer_digest"]
        say "Correct!"
      else
        say "Incorrect."
        say "I encourage you to try reviewing the material to see what the correct answer is."
      end
    end
  end
end
