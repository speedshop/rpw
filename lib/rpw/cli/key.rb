module RPW
  class Key < SubCommandBase
    desc "register [EMAIL_ADDRESS]", "Change email registered with Speedshop. One-time only."
    def register(email)
      unless client.setup?
        say "You have not yet set up the client. Run $ rpw start"
        exit(1)
      end
      if client.register_email(email)
        say "Key registered with #{email}. You should receive a Slack invite soon."
      else
        say "Key has already been registered. If you believe this is in error," \
          " please email support@speedshop.co"
      end
    end
  end
end
