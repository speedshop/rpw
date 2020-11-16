module RPW
  class Bannerlord
    class << self
      def print_banner
        puts r
        if `tput cols 80`.to_i < 80
          puts small_banner
        else
          puts banner
        end
        puts reset
      end

      def r
        "\e[31m"
      end

      def reset
        "\e[0m"
      end

      def small_banner
        %(
       _____ _          _____     _ _
      |_   _| |_ ___   | __  |___|_| |___
        | | |   | -_|  |    -| .'| | |_ -|
        |_| |_|_|___|  |__|__|__,|_|_|___|
       _____         ___
      |  _  |___ ___|  _|___ ___ _____ ___ ___ ___ ___
      |   __| -_|  _|  _| . |  _|     | .'|   |  _| -_|
      |__|  |___|_| |_| |___|_| |_|_|_|__,|_|_|___|___|
       _ _ _         _       _
      | | | |___ ___| |_ ___| |_ ___ ___
      | | | | . |  _| '_|_ -|   | . | . |
      |_____|___|_| |_,_|___|_|_|___|  _|
                                    |_|
          #{reset})
      end

      def banner
        %(
                                 _____ _          _____     _ _
      +hmNMMMMMm/`  -ymMMNh/    |_   _| |_ ___   | __  |___|_| |___
      sMMMMMMMMMy   +MMMMMMMMy    | | |   | -_|  |    -| .'| | |_ -|
      yMMMMMMMMMMy` yMMMMMMMMN    |_| |_|_|___|  |__|__|__,|_|_|___|
       `dMMMMMMMMMMm:-dMMMMMMm:   _____         ___
        `sNMMMMMMMMMMs.:+sso:`   |  _  |___ ___|  _|___ ___ _____ ___ ___ ___ ___
          :dMMMMMMMMMMm/         |   __| -_|  _|  _| . |  _|     | .'|   |  _| -_|
      :oss+:.sNMMMMMMMMMMy`      |__|  |___|_| |_| |___|_| |_|_|_|__,|_|_|___|___|
     /mMMMMMMd-:mMMMMMMMMMMd.     _ _ _         _       _
     NMMMMMMMMy `hMMMMMMMMMMh    | | | |___ ___| |_ ___| |_ ___ ___
     yMMMMMMMM+  `dMMMMMMMMMy    | | | | . |  _| '_|_ -|   | . | . |
     /hNMMmy-  `/mMMMMMNmy/      |_____|___|_| |_,_|___|_|_|___|  _|
                                                               |_|
          #{reset})
      end
    end
  end
end
