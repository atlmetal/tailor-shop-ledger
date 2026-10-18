require "rails_helper"

RSpec.describe FixedCosts::MonthQuery do
  include_context "with a current shop"

  subject(:result) { described_class.call(shop:, month:) }

  let(:month) { Date.new(2026, 10, 20) }
  let(:rent) { create(:fixed_cost, shop:, name: "Arriendo del local") }
  let(:power) { create(:fixed_cost, shop:, name: "Luz", averaged: true) }

  before do
    create(:fixed_cost_amount, fixed_cost: rent, starts_on: Date.new(2026, 1, 1), amount: 900_000)
    create(:fixed_cost_amount, fixed_cost: power, starts_on: Date.new(2026, 1, 1), amount: 290_000)
  end

  it { expect(result.fixed_costs).to eq([ rent, power ]) }

  context "in October 2026, with 27 days from Monday to Saturday" do
    it { is_expected.to have_attributes(month: Date.new(2026, 10, 1), total: 1_190_000, work_days: 27, per_work_day: 44_074) }
  end

  context "in February 2026, with 24 days from Monday to Saturday" do
    let(:month) { Date.new(2026, 2, 1) }

    it { is_expected.to have_attributes(total: 1_190_000, work_days: 24, per_work_day: 49_583) }
  end

  context "for a shop that works Monday to Friday, in October 2026" do
    let(:shop) { create(:shop, work_days: [ 1, 2, 3, 4, 5 ]) }

    it { is_expected.to have_attributes(total: 1_190_000, work_days: 22, per_work_day: 54_091) }
  end

  context "with a change of the rent from November" do
    before { create(:fixed_cost_amount, fixed_cost: rent, starts_on: Date.new(2026, 11, 1), amount: 950_000) }

    it { expect(result.total).to eq(1_190_000) }
    it { expect(described_class.call(shop:, month: Date.new(2026, 11, 1)).total).to eq(1_240_000) }
  end

  context "with the electricity removed from October" do
    before { create(:fixed_cost_amount, fixed_cost: power, starts_on: Date.new(2026, 10, 1), amount: 0) }

    it { expect(result.total).to eq(900_000) }
    it { expect(result.fixed_costs).to eq([ rent ]) }
  end

  context "with another shop's fixed costs" do
    before { create(:fixed_cost_amount, fixed_cost: create(:fixed_cost), starts_on: Date.new(2026, 1, 1), amount: 500_000) }

    it { expect(result.total).to eq(1_190_000) }
  end
end
