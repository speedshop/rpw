module RPW
  class Lesson < SubCommandBase
    class_before :exit_with_no_key

    desc "next", "Proceed to the next lesson of the workshop"
    option :"no-open"
    def next
      say "Proceeding to next lesson..."
      content = client.next

      if content.nil?
        RPW::CLI.new.print_banner
        say "Congratulations!"
        say "You have completed the Rails Performance Workshop."
        exit(0)
      end

      client.download_and_extract(content)
      client.increment_current_lesson!(content["position"])
      display_content(content, !options[:"no-open"])
    end

    desc "complete", "Mark the current lesson as complete"
    def complete
      say "Marked current lesson as complete"
      client.complete
    end

    desc "list", "Show all available workshop lessons"
    def list
      say "All available workshop lessons:"
      client.list.each do |lesson|
        puts "#{"  " * lesson["indent"]}[#{lesson["position"]}]: #{lesson["title"]}"
      end
    end

    desc "download [CONTENT | all]", "Download one or all workshop contents"
    def download(content_pos)
      to_download = if content_pos.downcase == "all"
        client.list
      else
        [client.show(content_pos)]
      end
      to_download.each { |content| client.download_and_extract(content) }
    end

    desc "show [CONTENT]", "Show any workshop lesson, shows current lesson w/no arguments"
    option :"no-open"
    def show(content_order = :current)
      content = client.show(content_order)
      client.download_and_extract(content)
      display_content(content, !options[:"no-open"])
    end

    private

    def display_content(content, open_after)
      say "Current Lesson: #{content["title"]}"
      openable = false
      case content["style"]
      when "video"
        location = "video/#{content["s3_key"]}"
        openable = true
      when "quiz"
        Quiz.start(["give_quiz", "quiz/" + content["s3_key"]])
      when "lab"
        location = "lab/#{content["s3_key"][0..-8]}"
      when "text"
        location = "lab/#{content["s3_key"]}"
        openable = true
      when "cgrp"
        say "The Complete Guide to Rails Performance has been downloaded and extracted to the ./cgrp directory."
        say "All source code for the CGRP is in the src directory, PDF and other compiled formats are in the release directory."
      end
      if location
        if openable && !open_after
          say "This file can be opened automatically if you use the --open flag next time."
          say "e.g. $ rpw lesson next --open"
          say "Download complete. Open with: $ #{open_command} #{location}"
        elsif open_after && openable
          exec "#{open_command} #{location}"
        end
      end
    end

    require "rbconfig"
    def open_command
      host_os = RbConfig::CONFIG["host_os"]
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
end
