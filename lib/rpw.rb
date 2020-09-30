module RPW
  VERSION = "0.0.1"

  class Gateway
    def get_resource(resource)
    end
  end

  class Command
  end

  module Commands
    class Setup < Command
      # if it doesn't exist, create rpw directory
      # ask for user purchase key
      # write purchase key to file
      # check by reading back the purchase key from the file and printing
    end
  end
end
