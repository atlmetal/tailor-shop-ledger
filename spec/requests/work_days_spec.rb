require "rails_helper"

RSpec.describe "Work days", type: :request do
  include_context "with a signed-in user"

  describe "PATCH /work_days" do
    let(:work_days) { [ "", "1", "2", "3", "4", "5" ] }

    before { patch work_days_path, params: { shop: { work_days: } } }

    it { expect(response).to redirect_to(fixed_costs_path) }
    it { expect(user.shop.reload.work_days).to eq([ 1, 2, 3, 4, 5 ]) }

    context "with no day left" do
      let(:work_days) { [ "" ] }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(response.parsed_body.at(".tape-panel").text.squish).to eq("Mark at least one day to work out your daily goal.") }
      it { expect(response.parsed_body.css("button.work-day[aria-pressed='true']")).to be_empty }
      it { expect(response.parsed_body.css("[aria-current='page']").map { it.text.squish }).to eq([ "Shop", "Fixed costs" ]) }
      it { expect(user.shop.reload.work_days).to eq([ 1, 2, 3, 4, 5, 6 ]) }
    end
  end
end
