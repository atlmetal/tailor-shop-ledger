require "rails_helper"

RSpec.describe ResultsHelper, type: :helper do
  let(:result) { instance_double(Results::PeriodQuery::Result, total:) }

  context "with a profit" do
    let(:total) { 0 }

    it { expect(helper.result_word(result)).to have_css("span.text-note", text: "Profit") }
    it { expect(helper.result_word(result, size: :large)).to have_css("span.font-extrabold svg.size-6") }
    it { expect(helper.result_name(result)).to eq("Profit") }
    it { expect(helper.result_amount_class(result)).to be_nil }
    it { expect(helper.result_panel_class(result)).to eq("result-profit") }
  end

  context "with a loss" do
    let(:total) { -47_000 }

    it { expect(helper.result_word(result)).to have_css(".text-loss-ink", text: "Loss") }
    it { expect(helper.result_name(result)).to eq("Loss") }
    it { expect(helper.result_amount_class(result)).to eq("text-loss-ink") }
    it { expect(helper.result_panel_class(result)).to eq("result-loss") }
  end
end
