require "rails_helper"

RSpec.describe Questions::OtherStatesController do
  let(:intake) { create :intake, state: "nd" }

  before do
    allow(subject).to receive(:user_signed_in?).and_return(true)
    allow(subject).to receive(:current_intake).and_return(intake)
  end

  describe "#edit" do
    render_views

    it "displays the state that we assume the user lived in" do
      get :edit

      expect(response.body).to include "did you live or work in any other states besides North Dakota?"
    end
  end
end
