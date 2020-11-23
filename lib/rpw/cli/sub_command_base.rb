module RPW
  class SubCommandBase < Thor
    def self.banner(command, namespace = nil, subcommand = false)
      "#{basename} #{subcommand_prefix} #{command.usage}"
    end

    def self.subcommand_prefix
      name.gsub(%r{.*::}, "").gsub(%r{^[A-Z]}) { |match| match[0].downcase }
        .gsub(%r{[A-Z]}) { |match| "-#{match[0].downcase}" }
    end

    no_commands do
      def client
        @client ||= RPW::Client.new
      end
    end
  end
end
