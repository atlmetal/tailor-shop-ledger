require "rails_helper"

RSpec.describe NewFixedCost, type: :model do
  subject(:new_fixed_cost) { described_class.new(shop:, name: "Arriendo del local", amount: "900,000", starts_on: "2026-10-01", **attributes) }

  let(:shop) { build_stubbed(:shop, started_on: Date.new(2026, 10, 1)) }
  let(:attributes) { {} }

  before do
    travel_to Date.new(2026, 10, 20)
    new_fixed_cost.validate
  end

  it { is_expected.to be_valid }
  it { expect(new_fixed_cost.months).to eq([ Date.new(2026, 10, 1), Date.new(2026, 11, 1), Date.new(2026, 12, 1) ]) }

  context "when the shop started in an earlier month" do
    let(:shop) { build_stubbed(:shop, started_on: Date.new(2026, 8, 12)) }
    let(:attributes) { { starts_on: "2026-08-01" } }

    it { is_expected.to be_valid }
    it { expect(new_fixed_cost.months).to eq([ Date.new(2026, 8, 1), Date.new(2026, 10, 1), Date.new(2026, 11, 1), Date.new(2026, 12, 1) ]) }
  end

  context "from a month before the shop started" do
    let(:attributes) { { starts_on: "2026-09-01" } }

    it { expect(new_fixed_cost.errors).to be_added(:starts_on, :inclusion, value: Date.new(2026, 9, 1)) }
  end

  context "without a name" do
    let(:attributes) { { name: "" } }

    it { expect(new_fixed_cost.errors).to be_added(:name, :blank) }
  end

  context "without an amount" do
    let(:attributes) { { amount: "" } }

    it { expect(new_fixed_cost.errors).to be_added(:amount, :blank, value: nil, count: 0) }
  end
end
