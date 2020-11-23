require "thor"
require "thor/hollaback"
require "rpw"
require "rpw/cli/bannerlord"
require "rpw/cli/sub_command_base"
require "rpw/cli/key"
require "rpw/cli/lesson"
require "rpw/cli/progress"
require "cli/ui"

CLI::UI::StdoutRouter.enable

module RPW
  class CLI < Thor
    class_before :check_version

    desc "key register [EMAIL_ADDRESS]", "Change email registered w/Speedshop"
    subcommand "key", Key
    desc "lesson [SUBCOMMAND]", "View and download lessons"
    subcommand "lesson", Lesson
    desc "progress [SUBCOMMAND]", "View and set progress"
    subcommand "progress", Progress

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

      puts ""
      say "Successfully authenticated with the RPW server and saved your key."
      puts ""
      say "Setup complete!"
      puts ""
      say "To learn how to use this command-line client, consult ./README.md, which we just created."
      say "Once you've read that and you're ready to get going: $ rpw lesson next"
    end

    no_commands do
      def print_banner
        RPW::Bannerlord.print_banner
      end
    end

    private

    def client
      @client ||= RPW::Client.new
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
