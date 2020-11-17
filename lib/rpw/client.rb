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
      gateway.authenticate_key(key)
      client_data["key"] = key
    end

    def register_email(email)
      gateway.register_email(email)
    end

    def next
      contents = gateway.list_content
      return contents.first unless client_data["completed"]
      contents.delete_if { |c| client_data["completed"].include? c["position"] }
      contents.sort_by { |c| c["position"] }[1] # 0 would be the current lesson
    end

    def list
      gateway.list_content
    end

    def show(content_pos)
      content_pos = client_data["current_lesson"] if content_pos == :current
      gateway.get_content_by_position(content_pos)
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

      File.open("README.md", "w+") do |f|
        f.puts File.read(File.join(File.dirname(__FILE__), "README.md"))
      end
    end

    def increment_current_lesson!(position)
      mark_current_lesson_as_completed
      client_data["current_lesson"] = position
    end

    def progress
      contents = gateway.list_content
      completed_lessons = client_data["completed"] || []
      {
        completed: completed_lessons.size,
        total: contents.size,
        current_lesson: contents.find { |c| c["position"] == client_data["current_lesson"] },
        sections: chart_section_progress(contents, completed_lessons)
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
      return true unless ClientData.exists?

      if client_data["last_version_check"]
        return true if client_data["last_version_check"] >= Time.now - (60 * 60 * 24)
        return false if client_data["last_version_check"] == false
      end

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

    private

    def mark_current_lesson_as_completed
      reset_progress unless client_data["current_lesson"] && client_data["completed"]
      client_data["completed"] ||= []
      client_data["completed"] += [client_data["current_lesson"] || 0]
    end

    def chart_section_progress(contents, completed)
      contents.group_by { |c| c["position"] / 100 }
        .each_with_object([]) do |(_, c), memo|
          completed_str = c.map { |l|
            if l["position"] == client_data["current_lesson"]
              "O"
            elsif completed.include?(l["position"])
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

    def client_data
      @client_data ||= ClientData.new
    end

    def extract_content(content)
      folder = content["style"]
      `tar -C #{folder} -xvzf #{folder}/#{content["s3_key"]}`
    end
  end
end
