require "rails_helper"

RSpec.describe AdvancesHelper, type: :helper do
  let(:advance) { instance_double(Advance, to_param: "4", customer_name: "Hotel Almendros", since: Date.new(2026, 10, 1), jobs:, top_ups:) }
  let(:jobs) { [] }
  let(:top_ups) { [] }

  describe "#balance_word" do
    it { expect(helper.balance_word(109_000)).to eq("Still has") }
    it { expect(helper.balance_word(0)).to eq("Still has") }
    it { expect(helper.balance_word(-4_000)).to eq("Owes you") }
  end

  describe "#advance_since" do
    it { expect(helper.advance_since(advance)).to eq("Advance since October 1") }

    context "without top-ups or jobs yet" do
      let(:advance) { instance_double(Advance, since: nil) }

      it { expect(helper.advance_since(advance)).to be_nil }
    end
  end

  describe "#advance_link" do
    it { expect(helper.advance_link(advance)).to have_link("Advance from Hotel Almendros", href: "/advances/4") }
  end

  describe "#advance_summary" do
    let(:advance) { instance_double(Advance, balance: -4_000, given: 120_000, charged: 124_000) }

    it("says what the customer owes, without a sign") { expect(helper.advance_summary(advance)).to have_text("Owes you $4,000 Gave you $120,000, and you've done $124,000 in jobs for them.", normalize_ws: true) }
  end

  describe "#advance_units" do
    let(:jobs) { [ instance_double(Job, quantity: 3), instance_double(Job, quantity: 1) ] }

    it { expect(helper.advance_units(advance)).to eq("4 jobs") }

    context "without jobs yet" do
      let(:jobs) { [] }

      it { expect(helper.advance_units(advance)).to be_nil }
    end
  end

  describe "#advance_jobs" do
    it { expect(helper.advance_jobs(advance)).to have_text("No jobs for them yet.") }

    context "with a job" do
      let(:jobs) { [ instance_double(Job, advance: instance_double(Advance, to_param: "4"), to_param: "7", quantity: 2, service: instance_double(Service, name: "Forro de chaqueta"), done_on: Date.new(2026, 10, 19), charged: 70_000) ] }

      it("shows its date instead of its materials") { expect(helper.advance_jobs(advance)).to have_link("2 × Forro de chaqueta October 19 $70,000", href: "/advances/4/jobs/7/edit", normalize_ws: true) }
    end
  end

  describe "#advance_top_ups" do
    it { expect(helper.advance_top_ups(advance)).to have_text("They haven't given you any money yet.") }

    context "with a top-up" do
      let(:top_ups) { [ instance_double(TopUp, advance: instance_double(Advance, to_param: "4"), to_param: "5", paid_on: Date.new(2026, 10, 16), amount: 100_000) ] }

      it { expect(helper.advance_top_ups(advance)).to have_link("Friday, October 16 $100,000", href: "/advances/4/top_ups/5/edit", normalize_ws: true) }
    end
  end

  describe "#top_up_balance_hint" do
    it { expect(helper.top_up_balance_hint(instance_double(TopUp, persisted?: false, advance_balance: 109_000))).to eq("They have $109,000 left.") }
    it { expect(helper.top_up_balance_hint(instance_double(TopUp, persisted?: false, advance_balance: -4_000))).to eq("Owes you $4,000.") }
    it { expect(helper.top_up_balance_hint(instance_double(TopUp, persisted?: true, advance_balance: 9_000))).to eq("Without this top-up, they have $9,000 left.") }
    it { expect(helper.top_up_balance_hint(instance_double(TopUp, persisted?: true, advance_balance: -91_000))).to eq("Without this top-up, owes you $91,000.") }
  end

  describe "#delete_advance" do
    it { expect(helper.delete_advance(advance)).to have_button("Delete advance") }

    context "with jobs" do
      let(:jobs) { [ instance_double(Job) ] }

      it("can't delete it, since its jobs counted") { expect(helper.delete_advance(advance)).to be_nil }
    end
  end
end
