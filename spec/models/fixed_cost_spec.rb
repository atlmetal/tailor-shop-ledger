require "rails_helper"

RSpec.describe FixedCost, type: :model do
  include_context "with a current shop"

  subject(:fixed_cost) { create(:fixed_cost, shop:) }

  let(:september) { Date.new(2026, 9, 1) }
  let(:october) { Date.new(2026, 10, 1) }
  let(:november) { Date.new(2026, 11, 1) }

  context "without a name" do
    subject(:fixed_cost) { build(:fixed_cost, shop:, name: " ") }

    before { fixed_cost.validate }

    it { expect(fixed_cost.errors).to be_added(:name, :blank) }
  end

  context "with an amount from September and a change from November" do
    before do
      create(:fixed_cost_amount, fixed_cost:, starts_on: september, amount: 900_000)
      create(:fixed_cost_amount, fixed_cost:, starts_on: november, amount: 950_000)
      fixed_cost.reload
    end

    it { expect(fixed_cost.amount_on(Date.new(2026, 8, 1))).to eq(0) }
    it { expect(fixed_cost.amount_on(october)).to eq(900_000) }
    it { expect(fixed_cost.amount_on(Date.new(2026, 12, 1))).to eq(950_000) }
    it { expect(fixed_cost.change_after(october)).to have_attributes(starts_on: november, amount: 950_000) }
    it { expect(fixed_cost.change_after(november)).to be_nil }
    it { expect(fixed_cost).not_to be_changed_on(october) }
    it { expect(fixed_cost).to be_changed_on(november) }
  end

  context "with its first amount from this month" do
    before do
      create(:fixed_cost_amount, fixed_cost:, starts_on: october)
      fixed_cost.reload
    end

    it { expect(fixed_cost).not_to be_changed_on(october) }
  end

  context "when removed from October" do
    before do
      create(:fixed_cost_amount, fixed_cost:, starts_on: september)
      create(:fixed_cost_amount, fixed_cost:, starts_on: october, amount: 0)
      fixed_cost.reload
    end

    it { expect(fixed_cost).to be_listed_on(september) }
    it { expect(fixed_cost).not_to be_listed_on(october) }
  end

  context "when removed from November" do
    before do
      create(:fixed_cost_amount, fixed_cost:, starts_on: september)
      create(:fixed_cost_amount, fixed_cost:, starts_on: november, amount: 0)
      fixed_cost.reload
    end

    it { expect(fixed_cost).to be_listed_on(october) }
  end

  context "when 0 this month, with a change from next month" do
    before do
      create(:fixed_cost_amount, fixed_cost:, starts_on: october, amount: 0)
      create(:fixed_cost_amount, fixed_cost:, starts_on: november, amount: 70_000)
      fixed_cost.reload
    end

    it { expect(fixed_cost).to be_listed_on(october) }
  end
end
