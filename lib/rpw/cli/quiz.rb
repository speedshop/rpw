require "digest"
require "thor"

module RPW
  class Quiz < Thor
    desc "give_quiz FILENAME", ""
    def give_quiz(filename)
      @quiz_data = YAML.safe_load(File.read(filename))
      @quiz_data["questions"].each { |q| question(q) }
    end

    private

    def question(data)
      puts data["prompt"]
      data["answer_choices"].each { |ac| puts ac }
      provided_answer = ask("Your answer?")
      answer_digest = Digest::MD5.hexdigest(data["prompt"] + provided_answer.upcase)
      if answer_digest == data["answer_digest"]
        say "Correct!"
      else
        say "Incorrect."
        say "I encourage you to try reviewing the material to see what the correct answer is."
      end
      say ""
    end
  end
end
