module Questions
  class HealthInsuranceController < QuestionsController
    layout "yes_no_question"

    def section_title
      "Income and Expenses"
    end
  end
end
