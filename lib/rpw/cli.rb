require "thor"
require "thor/hollaback"
require "rpw"
require "rpw/cli/bannerlord"
require "rpw/cli/sub_command_base"
require "rpw/cli/key"
require "cli/ui"

CLI::UI::StdoutRouter.enable

module RPW
  class CLI < Thor
    class_before :check_version

    desc "key register [EMAIL_ADDRESS]", "Change email registered w/Speedshop"
    subcommand "key", Key

    def self.exit_on_failure?
      true
    end

    desc "start", "Tutorial and onboarding"
    def start
      warn_if_already_started

      print_banner
      say "\u{1F48E} Welcome to the Rails Performance Workshop. \u{1F48E}"
      say ""
      say "This is rpw, the command line client for this workshop."
      say ""
      say "This client will download files from the internet into the current"
      say "working directory, so it's best to run this client from a new directory"
      say "that you'll use as your 'scratch space' for working on the Workshop."
      say ""

      ans = ::CLI::UI.confirm "Create files and folders in this directory? (no will quit)"

      exit(1) unless ans

      say ""

      ans = ::CLI::UI::Prompt.ask("Where should we save your course progress?",
        options: [
          "here",
          "my home directory (~/.rpw)"
        ])

      client.directory_setup((ans == "my home directory (~/.rpw)"))

      key = ::CLI::UI::Prompt.ask("Your Purchase Key: ")

      unless client.setup(key)
        say "That is not a valid key. Please try again."
        exit(0)
      end

      say ""
      say "Successfully authenticated with the RPW server and saved your key."
      say ""
      say "Setup complete!"
      say ""
      say "To learn how to use this command-line client, consult ./README.md,"
      say "which we just created."
      say ""
      say "Once you've read that and you're ready to get going: $ rpw next"
    end

    desc "next", "Proceed to the next lesson of the workshop"
    option :"no-open", type: :boolean
    def next
      exit_with_no_key
      content = client.next

      if content.nil?
        RPW::CLI.new.print_banner
        say "Congratulations!"
        say "You have completed the Rails Performance Workshop."
        exit(0)
      end

      say "Proceeding to next lesson: #{content["title"]}"
      client.download_and_extract(content)
      client.complete(content["position"])
      display_content(content, !options[:"no-open"])
    end

    desc "current", "Open the current lesson"
    option :"no-open", type: :boolean
    def current
      exit_with_no_key
      content = client.current
      say "Opening: #{content["title"]}"
      client.download_and_extract(content)
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

        no_data = client.send(:client_data)["completed"].nil?
        completed = client.send(:client_data)["completed"]&.include?(lesson["position"])

        str = if no_data
          ""
        elsif completed
          "\u{2705} "
        else
          "\u{274C} "
        end

        case lesson["style"]
        when "video"
          puts str + ::CLI::UI.fmt("{{red:#{lesson["title"]}}}")
        when "quiz"
          # puts ::CLI::UI.fmt "{{green:#{"  " + lesson["title"]}}}"
        when "lab"
          puts str + ::CLI::UI.fmt("{{yellow:#{"  " + lesson["title"]}}}")
        when "text"
          puts str + ::CLI::UI.fmt("{{magenta:#{"  " + lesson["title"]}}}")
        else
          puts str + ::CLI::UI.fmt("{{magenta:#{"  " + lesson["title"]}}}")
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
        current = client.list.index(content) + 1
        puts "Downloading #{content["title"]} (#{current}/#{total})"
        client.download_and_extract(content)
      end
    end

    desc "show", "Show any individal workshop lesson"
    option :"no-open", type: :boolean
    option :quizzes, type: :boolean
    def show
      exit_with_no_key
      title = ::CLI::UI::Prompt.ask(
        "Which lesson would you like to view?",
        options: client.list.reject { |l| !options[:quizzes] && l["title"] == "Quiz" }.map { |l| "  " * l["indent"] + l["title"] }
      )
      title.strip!
      content_order = client.list.find { |l| l["title"] == title }["position"]
      content = client.show(content_order)
      client.download_and_extract(content)
      display_content(content, !options[:"no-open"])
    end

    desc "set_progress", "Set current lesson to a particular lesson"
    def set_progress
      title = ::CLI::UI::Prompt.ask(
        "Which lesson would you like to set your progress to? All prior lessons will be marked complete",
        options: client.list.reject { |l| l["title"] == "Quiz" }.map { |l| "  " * l["indent"] + l["title"] }
      )
      title.strip!
      content_order = client.list.find { |l| l["title"] == title }["position"]
      content = client.set_progress(content_order, all_prior: true)
      say "Setting current progress to #{content.last["title"]}"
    end

    desc "reset", "Erase all progress and start over"
    def reset
      return unless ::CLI::UI.confirm("Are you sure you want to erase all of your progress?", default: false)
      say "Resetting progress."
      client.set_progress(nil)
    end

    no_commands do
      def print_banner
        RPW::Bannerlord.print_banner
      end
    end

    private

    def exit_with_no_key
      unless client.setup?
        say "You have not yet set up the client. Run $ rpw start"
        exit(1)
      end
      unless client.directories_ready?
        say "You are not in your workshop scratch directory, or you have not yet"
        say "set up the client. Change directory or run $ rpw start"
        exit(1)
      end
    end

    def client
      @client ||= RPW::Client.new
    end

    def display_content(content, open_after)
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
        say "You can check it out now, or to continue: $ rpw next "
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

    def warn_if_already_started
      return unless client.setup?
      exit(0) unless ::CLI::UI.confirm "You have already started the workshop. Continuing "\
        "this command will wipe all of your current progress. Continue?", default: false
    end

    def check_version
      unless client.latest_version?
        say "WARNING: You are running an old version of rpw."
        say "WARNING: Please run `$ gem install rpw`"
      end
    end
  end
end
