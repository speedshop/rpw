module RPW 
  class SubCommandBase < Thor
    def self.banner(command, namespace = nil, subcommand = false)
      "#{basename} #{subcommand_prefix} #{command.usage}"
    end

    def self.subcommand_prefix
      name.gsub(%r{.*::}, "").gsub(%r{^[A-Z]}) { |match| match[0].downcase }.
        gsub(%r{[A-Z]}) { |match| "-#{match[0].downcase}" }
    end

    no_commands do
      def client
        @client ||= RPW::Client.new
      end

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
    end
  end
end