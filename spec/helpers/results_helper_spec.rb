require "rails_helper"

RSpec.describe ResultsHelper, type: :helper do
  let(:result) { instance_double(Results::PeriodQuery::Result, total:) }

  context "with a profit" do
    let(:total) { 0 }

    it { expect(helper.result_word(result)).to have_text("Profit") }
    it { expect(helper.result_amount_class(result)).to be_nil }
  end

  context "with a loss" do
    let(:total) { -47_000 }

    it { expect(helper.result_word(result)).to have_css(".text-loss-ink", text: "Loss") }
    it { expect(helper.result_amount_class(result)).to eq("text-loss-ink") }
  end
end
