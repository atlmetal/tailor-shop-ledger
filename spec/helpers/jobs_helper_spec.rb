require "rails_helper"

RSpec.describe JobsHelper, type: :helper do
  describe "#job_saved_notice" do
    subject(:notice) { helper.job_saved_notice }

    it { is_expected.to be_nil }

    context "after saving and recording another" do
      before { flash[:saved] = "2 × Basta de pantalón, $16,000" }

      it { is_expected.to have_css("[role='status'] strong", text: "Saved:") }
      it { is_expected.to have_text("Saved: 2 × Basta de pantalón, $16,000. Go on with the next one.") }
    end
  end
end
