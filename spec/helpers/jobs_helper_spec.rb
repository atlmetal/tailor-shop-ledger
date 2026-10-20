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
    it { expect(helper.edit_job_path_for(instance_double(Job, order: nil, advance: nil, to_param: "7"))).to eq("/jobs/7/edit") }
    it("opens a job in an order under it") { expect(helper.edit_job_path_for(instance_double(Job, order: instance_double(Order, to_param: "3"), to_param: "7"))).to eq("/orders/3/jobs/7/edit") }
    it("opens a job in an advance under it") { expect(helper.edit_job_path_for(instance_double(Job, order: nil, advance: instance_double(Advance, to_param: "4"), to_param: "7"))).to eq("/advances/4/jobs/7/edit") }
  end

  describe "#job_form_text" do
    it { expect(helper.job_form_text(instance_double(Job, order: nil, advance: nil), :service)).to eq("Which service did you do?") }
    it("speaks of work still to do in an order") { expect(helper.job_form_text(instance_double(Job, order: instance_double(Order)), :price_hint)).to eq("Change it if you agreed on another price.") }
    it("speaks of work for the customer in an advance") { expect(helper.job_form_text(instance_double(Job, order: nil, advance: instance_double(Advance)), :service)).to eq("Which service did you do for them?") }
  end

  describe "#job_balance" do
    subject(:panel) { helper.job_balance(job) }

    let(:job) { instance_double(Job, advance: instance_double(Advance), advance_balance: 109_000, charged: 70_000) }

    it { is_expected.to have_css("[data-job-form-target='balance'][data-balance='109000']") }
    it { is_expected.to have_text("Advance balance $109,000 This job −$70,000 Would still have $39,000", normalize_ws: true) }
    it { is_expected.to have_css("[data-job-form-target='debt'][hidden]", visible: :hidden) }

    context "past the balance" do
      let(:job) { instance_double(Job, advance: instance_double(Advance), advance_balance: 109_000, charged: 140_000) }

      it("warns how much the customer would owe") { is_expected.to have_css("[role='status']", text: "The customer would owe $31,000.") }
      it { is_expected.to have_css("[data-job-form-target='left'][hidden]", visible: :hidden) }
    end

    context "for a job on its own" do
      let(:job) { instance_double(Job, advance: nil) }

      it { is_expected.to be_nil }
    end
  end
end
