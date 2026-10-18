require "rails_helper"

RSpec.describe FixedCostsHelper, type: :helper do
  let(:september) { Date.new(2026, 9, 1) }
  let(:october) { Date.new(2026, 10, 1) }
  let(:november) { Date.new(2026, 11, 1) }

  describe "#fixed_cost_notes" do
    subject(:notes) { helper.fixed_cost_notes(fixed_cost, october) }

    let(:fixed_cost) { instance_double(FixedCost, averaged?: averaged, change_after: change, changed_on?: changed) }
    let(:averaged) { false }
    let(:change) { nil }
    let(:changed) { false }

    it { is_expected.to eq("") }

    context "when averaged" do
      let(:averaged) { true }

      it { is_expected.to eq('<span class="text-meta text-graphite">Average</span>') }
    end

    context "with a change scheduled" do
      let(:change) { instance_double(FixedCostAmount, starts_on: november, amount: 950_000) }

      it { is_expected.to eq('<span class="text-meta text-graphite">From November: $950,000</span>') }
    end

    context "with its removal scheduled" do
      let(:change) { instance_double(FixedCostAmount, starts_on: november, amount: 0) }

      it { is_expected.to eq('<span class="text-meta text-graphite">Removed from November</span>') }
    end

    context "when changed from this month" do
      let(:changed) { true }

      before { allow(fixed_cost).to receive(:amount_on).with(september).and_return(900_000) }

      it { is_expected.to eq('<span class="text-meta text-graphite">Until September: $900,000</span>') }
    end
  end

  describe "#change_helps" do
    subject(:helps) { helper.change_helps(fixed_cost, [ october, november, Date.new(2026, 12, 1) ]) }

    let(:fixed_cost) { instance_double(FixedCost) }

    before do
      allow(fixed_cost).to receive(:amount_on).with(september).and_return(880_000)
      allow(fixed_cost).to receive(:amount_on).with(october).and_return(900_000)
    end

    it do
      is_expected.to eq([
        "October already counts the new amount. September and the months before keep $880,000.",
        "October and the months before keep $900,000.",
        "October, November and the months before keep $900,000."
      ])
    end

    context "in es-CO, whose month names are lowercase" do
      subject(:helps) { I18n.with_locale(:"es-CO") { helper.change_helps(fixed_cost, [ october, november, Date.new(2026, 12, 1) ]) } }

      it do
        is_expected.to eq([
          "Octubre ya se calcula con el valor nuevo. Septiembre y los meses anteriores siguen con $880.000.",
          "Octubre y los meses anteriores siguen con $900.000.",
          "Octubre, noviembre y los meses anteriores siguen con $900.000."
        ])
      end
    end
  end

  describe "#month_options" do
    before { travel_to Date.new(2026, 10, 20) }

    it { expect(helper.month_options([ october, november ])).to eq([ [ "October 2026", "2026-10-01" ], [ "November 2026", "2026-11-01" ] ]) }
    it { expect(I18n.with_locale(:"es-CO") { helper.month_options([ october ]) }).to eq([ [ "octubre de 2026", "2026-10-01" ] ]) }

    it "says which is the month the shop started, when it's earlier" do
      expect(helper.month_options([ Date.new(2026, 8, 1), october ], started_on: Date.new(2026, 8, 12)))
        .to eq([ [ "August 2026, when you started", "2026-08-01" ], [ "October 2026", "2026-10-01" ] ])
    end
  end
end
