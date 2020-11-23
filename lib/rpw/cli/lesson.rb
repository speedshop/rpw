module RPW
  class Lesson < SubCommandBase
    desc "next", "Proceed to the next lesson of the workshop"
    option :"no-open"
    def next
      exit_with_no_key
      say "Proceeding to next lesson..."
      content = client.next

      if content.nil?
        RPW::CLI.new.print_banner
        say "Congratulations!"
        say "You have completed the Rails Performance Workshop."
        exit(0)
      end

      client.download_and_extract(content)
      client.complete(content["position"])
      display_content(content, !options[:"no-open"])
    end

    desc "complete", "Mark the current lesson as complete"
    def complete
      say "Marked current lesson as complete"
      client.complete(nil)
    end

    desc "list", "Show all available workshop lessons"
    def list
      ::CLI::UI::Frame.open("{{*}} {{bold:All Lessons}}", color: :green)

      frame_open = false
      client.list.each do |lesson|
        if lesson["title"].start_with?("Section")
          ::CLI::UI::Frame.close(nil) if frame_open
          ::CLI::UI::Frame.open(lesson["title"])
          frame_open = true
          next
        end

        case lesson["style"]
        when "video"
          puts ::CLI::UI.fmt "{{red:#{lesson["title"]}}}"
        when "quiz"
          # puts ::CLI::UI.fmt "{{green:#{"  " + lesson["title"]}}}"
        when "lab"
          puts ::CLI::UI.fmt "{{yellow:#{"  " + lesson["title"]}}}"
        when "text"
          puts ::CLI::UI.fmt "{{magenta:#{"  " + lesson["title"]}}}"
        else
          puts ::CLI::UI.fmt "{{magenta:#{"  " + lesson["title"]}}}"
        end
      end

      ::CLI::UI::Frame.close(nil)
      ::CLI::UI::Frame.close(nil, color: :green)
    end

    desc "download", "Download all workshop contents"
    def download
      exit_with_no_key
      total = client.list.size
      client.list.each do |content|
        current = client.list.index(content)
        puts "Downloading #{content["title"]} (#{current}/#{total})"
        client.download_and_extract(content)
      end
    end

    desc "show", "Show any individal workshop lesson"
    option :"no-open"
    def show
      exit_with_no_key
      title = ::CLI::UI::Prompt.ask(
        "Which lesson would you like to view?",
        options: client.list.reject { |l| l["title"] == "Quiz" }.map { |l| "  " * l["indent"] + l["title"] }
      )
      title.strip!
      content_order = client.list.find { |l| l["title"] == title }["position"]
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
        openable = true
      when "text"
        location = "text/#{content["s3_key"]}"
        openable = true
      when "cgrp"
        say "The Complete Guide to Rails Performance has been downloaded and extracted to the ./cgrp directory."
        say "All source code for the CGRP is in the src directory, PDF and other compiled formats are in the release directory."
        say "You can check it out now, or to continue: $ rpw lesson next "
      end
      if location
        if openable && !open_after
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
