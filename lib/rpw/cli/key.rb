module RPW 
  class Key < SubCommandBase
    class_before :exit_with_no_key
    
    desc "register [EMAIL_ADDRESS]", "Change email registered with Speedshop. One-time only."
    def register(email)
      if client.register_email(email)
        say "Key registered with #{email}. You should receive a Slack invite soon." 
      else   
        say "Key has already been registered. If you believe this is in error,"\
          " please email nate.berkopec@speedshop.co"
      end
    end
  end
end