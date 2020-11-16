module RPW
  class Progress < SubCommandBase
    class_before :exit_with_no_key

    desc "set [LESSON]", "Set current lesson to a particular lesson"
    def set(lesson)
      client.set_progress(lesson)
    end

    desc "reset", "Erase all progress and start over"
    def reset
      yes? "Are you sure you want to reset your progress? (Y/N)"
      client.reset_progress
    end

    desc "show", "Show current workshop progress"
    def show
      data = client.progress
      say "The Rails Performance Workshop"
      say "You have completed #{data[:completed]} out of #{data[:total]} total sections."
      say "Current lesson: #{data[:current_lesson]["title"]}" if data[:current_lesson]
      say "Progress by Section (X == completed, O == current):"
      data[:sections].each do |section|
        say "#{section[:title]}: #{section[:progress]}"
      end
    end

    private

    default_task :show
  end
end
