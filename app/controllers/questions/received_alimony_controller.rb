module Questions
  class ReceivedAlimonyController < QuestionsController
    layout "yes_no_question"

    def self.show?(intake)
      intake.ever_married_yes?
    end

    def section_title
      "Income and Expenses"
    end
  end
end