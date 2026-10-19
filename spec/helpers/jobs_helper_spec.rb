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

  describe "#edit_job_path_for" do
    it { expect(helper.edit_job_path_for(instance_double(Job, order: nil, to_param: "7"))).to eq("/jobs/7/edit") }
    it("opens a job in an order under it") { expect(helper.edit_job_path_for(instance_double(Job, order: instance_double(Order, to_param: "3"), to_param: "7"))).to eq("/orders/3/jobs/7/edit") }
  end

  describe "#job_form_text" do
    it { expect(helper.job_form_text(instance_double(Job, order: nil), :service)).to eq("Which service did you do?") }
    it("speaks of work still to do in an order") { expect(helper.job_form_text(instance_double(Job, order: instance_double(Order)), :price_hint)).to eq("Change it if you agreed on another price.") }
  end
end
