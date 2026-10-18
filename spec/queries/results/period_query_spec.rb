require "rails_helper"

RSpec.describe Results::PeriodQuery do
  include_context "with a current shop"

  subject(:result) { described_class.call(shop:, period:) }

  let(:shop) { create(:shop, started_on: Date.new(2026, 8, 3)) }
  let(:service) { create(:service, shop:, price: 8_000, material_cost: 500) }
  let(:period) { Date.new(2026, 10, 1)..Date.new(2026, 10, 31) }

  before do
    travel_to Date.new(2026, 10, 20)
    create(:fixed_cost_amount, fixed_cost: create(:fixed_cost, shop:), starts_on: Date.new(2026, 8, 1), amount: 900_000)
    create(:fixed_cost_amount, fixed_cost: create(:fixed_cost, shop:), starts_on: Date.new(2026, 8, 1), amount: 290_000)
  end

  context "with a period in progress" do
    before do
      create(:job, service:, done_on: Date.new(2026, 9, 30))
      create(:job, service:, done_on: Date.new(2026, 10, 1), quantity: 2)
      create(:job, service:, done_on: Date.new(2026, 10, 20), quantity: 1, price: 10_000)
      create(:entry, shop:, kind: "income", occurred_on: Date.new(2026, 10, 9), amount: 20_000)
      create(:entry, shop:, kind: "expense", occurred_on: Date.new(2026, 10, 14), amount: 35_000)
      create(:entry, shop:, kind: "expense", occurred_on: Date.new(2026, 10, 3), amount: 12_000)
    end

    it("counts up to today, today included") { is_expected.to have_attributes(days: Date.new(2026, 10, 1)..Date.new(2026, 10, 20), work_days: 17) }
    it("counts the units of each job") { expect(result.units).to eq(3) }
    it { is_expected.to have_attributes(charged: 26_000, materials: 1_500, incomes: 20_000, expenses: 47_000) }
    it("carries the fixed costs of the 17 work days so far") { expect(result.fixed_costs).to eq(749_259) }
    it { expect(result.total).to eq(26_000 - 1_500 + 20_000 - 47_000 - 749_259) }
  end

  context "with a period across two months" do
    let(:period) { Date.new(2026, 9, 28)..Date.new(2026, 10, 4) }

    it("carries 3 of September's 26 work days and 3 of October's 27") { is_expected.to have_attributes(work_days: 6, fixed_costs: 137_308 + 132_222) }
  end

  context "with a whole month" do
    let(:period) { Date.new(2026, 9, 1)..Date.new(2026, 9, 30) }

    it("carries exactly its fixed costs") { expect(result.fixed_costs).to eq(1_190_000) }
  end

  context "with a period starting before the shop did" do
    let(:period) { Date.new(2026, 7, 1)..Date.new(2026, 8, 31) }

    it("counts from the shop's start date") { is_expected.to have_attributes(days: Date.new(2026, 8, 3)..Date.new(2026, 8, 31), work_days: 25) }
    it("carries the fixed costs of the 25 work days of August it was open") { expect(result.fixed_costs).to eq(1_144_231) }
  end

  context "with a period before the shop started" do
    let(:period) { Date.new(2026, 7, 1)..Date.new(2026, 7, 31) }

    it { is_expected.to have_attributes(work_days: 0, fixed_costs: 0, charged: 0, total: 0) }
  end

  context "with a day off" do
    let(:period) { Date.new(2026, 10, 18)..Date.new(2026, 10, 18) }

    before { create(:job, service:, done_on: Date.new(2026, 10, 18), quantity: 2) }

    it("carries no fixed costs, and still counts what the shop made") { is_expected.to have_attributes(work_days: 0, fixed_costs: 0, charged: 16_000, total: 15_000) }
  end

  context "with another shop's jobs and entries" do
    before do
      create(:job, done_on: Date.new(2026, 10, 5))
      create(:entry, occurred_on: Date.new(2026, 10, 5))
    end

    it { is_expected.to have_attributes(charged: 0, expenses: 0) }
  end
end
