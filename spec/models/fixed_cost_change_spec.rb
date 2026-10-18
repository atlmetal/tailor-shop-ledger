require "rails_helper"

RSpec.describe FixedCostChange, type: :model do
  subject(:change) { described_class.new(amount: "950,000", starts_on: "2026-11-01", **attributes) }

  let(:attributes) { {} }

  before do
    travel_to Date.new(2026, 10, 20)
    change.validate
  end

  it { is_expected.to be_valid }
  it { expect(change.amount).to eq(950_000) }
  it { expect(described_class.months).to eq([ Date.new(2026, 10, 1), Date.new(2026, 11, 1), Date.new(2026, 12, 1) ]) }

  context "from an earlier month" do
    let(:attributes) { { starts_on: "2026-09-01" } }

    it { expect(change.errors).to be_added(:starts_on, :inclusion, value: Date.new(2026, 9, 1)) }
  end

  context "from a month after the next two" do
    let(:attributes) { { starts_on: "2027-01-01" } }

    it { expect(change.errors).to be_added(:starts_on, :inclusion, value: Date.new(2027, 1, 1)) }
  end

  context "without an amount" do
    let(:attributes) { { amount: "" } }

    it { expect(change.errors).to be_added(:amount, :blank, value: nil, count: 0) }
  end

  context "when it removes the fixed cost" do
    let(:attributes) { { amount: "", remove: "1" } }

    it { is_expected.to be_valid }
    it { expect(change.amount).to eq(0) }
  end
end
