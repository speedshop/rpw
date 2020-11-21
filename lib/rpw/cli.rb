require "thor"
require "thor/hollaback"
require "rpw"
require "rpw/cli/bannerlord"
require "rpw/cli/sub_command_base"
require "rpw/cli/key"
require "rpw/cli/lesson"
require "rpw/cli/progress"

module RPW
  class CLI < Thor
    class_before :check_version
    class_before :check_setup

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
      say "Welcome to the Rails Performance Workshop."
      say ""
      say "This is rpw, the command line client for this workshop."
      say ""
      say "This client will download files from the internet into the current"
      say "working directory, so it's best to run this client from a new directory"
      say "that you'll use as your 'scratch space' for working on the Workshop."
      say ""
      say "We will create a handful of new files and folders in the current directory."
      return unless yes? "Is this OK? (y/N) (N will quit)"
      puts ""
      say "We'll also create a .rpw_info file at #{File.expand_path("~/.rpw")} to save your purchase key."
      home_dir_ok = yes?("Is this OK? (y/N) (N will create it in the current directory)")
      client.directory_setup(home_dir_ok)

      key = ask("Your Purchase Key: ")

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
      exit(0) unless yes? "You have already started the workshop. Continuing "\
        "this command will wipe all of your current progress. Continue? (y/N)"
    end

    def check_version
      unless client.latest_version?
        say "WARNING: You are running an old version of rpw."
        say "WARNING: Please run `$ gem install rpw`"
        exit(0)
      end
    end

    def check_setup
      unless client.setup? || current_command_chain == [:start]
        say "WARNING: You do not have a purchase key set. Run `$ rpw start`"
        exit(0)
      end
    end
  end
end
