require "fileutils"
require "rpw/cli/quiz"

module RPW
  class Client
    RPW_SERVER_DOMAIN = ENV["RPW_SERVER_DOMAIN"] || "https://rpw-licensor.speedshop.co"
    attr_reader :gateway

    def initialize(gateway = nil)
      @gateway = gateway || Gateway.new(RPW_SERVER_DOMAIN, client_data["key"])
    end

    def setup(key)
      success = gateway.authenticate_key(key)
      client_data["key"] = key if success
      success
    end

    def register_email(email)
      gateway.register_email(email)
    end

    def next
      return list.first unless client_data["completed"]
      list.sort_by { |c| c["position"] }.find { |c| c["position"] > current_position }
    end

    def current
      return list.first unless client_data["completed"]
      list.sort_by { |c| c["position"] }.find { |c| c["position"] == current_position }
    end

    def list
      @list ||= if client_data["content_cache_generated"] &&
          client_data["content_cache_generated"] >= Time.now - 60 * 60

        client_data["content_cache"]
      else
        begin
          client_data["content_cache"] = gateway.list_content
          client_data["content_cache_generated"] = Time.now
          client_data["content_cache"]
        rescue
          client_data["content_cache"] || (raise Error.new("No internet connection"))
        end
      end
    end

    def show(content_pos)
      list.find { |l| l["position"] == content_pos }
    end

    def directory_setup(home_dir_ok = true)
      ["video", "quiz", "lab", "text", "cgrp"].each do |path|
        FileUtils.mkdir_p(path) unless File.directory?(path)
      end

      if home_dir_ok
        ClientData.create_in_home!
      else
        ClientData.create_in_pwd!
      end

      unless File.exist?(".gitignore") && File.read(".gitignore").match(/rpw_info/)
        File.open(".gitignore", "a") do |f|
          f.puts "\n"
          f.puts ".rpw_info\n"
          f.puts "video\n"
          f.puts "quiz\n"
          f.puts "lab\n"
          f.puts "text\n"
          f.puts "cgrp\n"
        end
      end

      File.open("README.md", "w+") do |f|
        f.puts File.read(File.join(File.dirname(__FILE__), "README.md"))
      end
    end

    def set_progress(pos, all_prior: false)
      client_data["completed"] = [] && return if pos.nil?
      if all_prior
        lessons = list.select { |l| l["position"] <= pos }
        client_data["completed"] = lessons.map { |l| l["position"] }
        lessons
      else
        lesson = list.find { |l| l["position"] == pos }
        client_data["completed"] += [pos]
        lesson
      end
    end

    def latest_version?
      return true unless ClientData.exists?
      return true if client_data["last_version_check"] &&
        client_data["last_version_check"] >= Time.now - (60 * 60)

      begin
        latest = gateway.latest_version?
      rescue
        return true
      end

      client_data["last_version_check"] = if latest
        Time.now
      else
        false
      end
    end

    def setup?
      return false unless ClientData.exists?
      client_data["key"]
    end

    def directories_ready?
      ["video", "quiz", "lab", "text", "cgrp"].all? do |path|
        File.directory?(path)
      end
    end

    def download_and_extract(content)
      location = content["style"] + "/" + content["s3_key"]
      unless File.exist?(location)
        gateway.download_content(content, folder: content["style"])
        extract_content(content) if content["s3_key"].end_with?(".tar.gz")
      end
    end

    def complete(position)
      if client_data["completed"]
        # we actually have to put the _next_ lesson on the completed stack
        set_progress(self.next["position"])
      else
        client_data["completed"] = []
        set_progress(position)
      end
    end

    private

    def current_position
      @current_position ||= client_data["completed"]&.last || 0
    end

    def client_data
      @client_data ||= ClientData.new
    end

    def extract_content(content)
      folder = content["style"]
      `tar -C #{folder} -xzf #{folder}/#{content["s3_key"]}`
    end
  end
end
