module RPW 
  class Lesson < SubCommandBase
    class_before :exit_with_no_key

    desc "next", "Proceed to the next lesson of the workshop"
    option :open
    def next
      say "Proceeding to next lesson..."
      client.next(options[:open])
    end

    desc "complete", "Mark the current lesson as complete"
    def complete
      say "Marked current lesson as complete"
      client.complete
    end

    desc "list", "Show all available workshop lessons"
    def list
      say "All available workshop lessons:"
      client.list.each do |lesson|
        puts "#{"  " * lesson["indent"]}[#{lesson["position"]}]: #{lesson["title"]}"
      end
    end

    desc "download [CONTENT | all]", "Download one or all workshop contents"
    def download(content)
      client.download(content)
    end

    desc "show [CONTENT]", "Show any workshop lesson, shows current lesson w/no arguments"
    option :open
    def show(content = :current)
      client.show(content, options[:open])
    end
  end
end