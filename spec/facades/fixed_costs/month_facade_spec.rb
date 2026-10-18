require "rails_helper"

RSpec.describe FixedCosts::MonthFacade do
  subject(:facade) { described_class.new(shop:, today: Date.new(2026, 10, 20), **options) }

  let(:shop) { instance_double(Shop) }
  let(:options) { {} }
  let(:rent) { instance_double(FixedCost) }
  let(:summary) { instance_double(FixedCosts::MonthQuery::Result, month: Date.new(2026, 10, 1), fixed_costs: [ rent ], total: 1_190_000, work_days: 27, per_work_day: 44_074) }

  before { allow(FixedCosts::MonthQuery).to receive(:call).with(shop:, month: Date.new(2026, 10, 20)).and_return(summary) }

  it { is_expected.to have_attributes(month: Date.new(2026, 10, 1), fixed_costs: [ rent ], total: 1_190_000, work_days: 27, per_work_day: 44_074) }
  it { expect(facade.change_for(rent)).to have_attributes(fixed_cost: rent, starts_on: Date.new(2026, 11, 1)) }
  it { expect(facade.change_months).to eq([ Date.new(2026, 10, 1), Date.new(2026, 11, 1), Date.new(2026, 12, 1) ]) }
  it { expect(facade.new_fixed_cost).to have_attributes(shop:, starts_on: Date.new(2026, 10, 1)) }

  context "when a change came back with its errors" do
    let(:change) { instance_double(FixedCostChange, fixed_cost: rent) }
    let(:options) { { change: } }

    it { expect(facade.change_for(rent)).to eq(change) }
    it { expect(facade.change_for(instance_double(FixedCost))).not_to eq(change) }
  end

  context "when a new fixed cost came back with its errors" do
    let(:new_fixed_cost) { instance_double(NewFixedCost) }
    let(:options) { { new_fixed_cost: } }

    it { expect(facade.new_fixed_cost).to eq(new_fixed_cost) }
  end
end
