module RPW
  class Progress < SubCommandBase
    desc "set [LESSON]", "Set current lesson to a particular lesson"
    def set(pos)
      lesson = client.set_progress(pos.to_i)
      say "Set current progress to #{lesson["title"]}"
    end

    desc "reset", "Erase all progress and start over"
    def reset
      return unless ::CLI::UI.confirm("Are you sure you want to erase all of your progress?", default: false)
      say "Resetting progress."
      client.set_progress(nil)
    end

    desc "show", "Show current workshop progress"
    def show
      data = client.progress
      ::CLI::UI::Frame.open("The Rails Performance Workshop", timing: false, color: :red) do
        say "You have completed #{data[:completed]} out of #{data[:total]} total sections."
        say ""
        say "Current lesson: #{data[:current_lesson]["title"]}" if data[:current_lesson]
        say ""
        ::CLI::UI::Frame.open("Progress", timing: false, color: :red) do
          puts ::CLI::UI.fmt "{{i}} (X == completed, O == current)"
          say ""
          data[:sections].each do |section|
            say "#{section[:title]}: #{section[:progress]}"
          end
        end
      end
    end

    private

    default_task :show
  end
end
