require "rails_helper"

RSpec.describe Entry, type: :model do
  include_context "with a current shop"

  subject(:entry) { described_class.new(kind: "expense", occurred_on: "2026-10-20", concept: "Transporte", amount: "12,000", **attributes) }

  let(:shop) { create(:shop, started_on: Date.new(2026, 10, 1)) }
  let(:attributes) { {} }

  before do
    travel_to Date.new(2026, 10, 20)
    entry.validate
  end

  it { is_expected.to be_valid }
  it { expect(entry.amount).to eq(12_000) }

  context "with spaces around and inside its concept" do
    let(:attributes) { { concept: "  Repuesto de  la máquina " } }

    it { expect(entry.concept).to eq("Repuesto de la máquina") }
  end

  context "without a concept" do
    let(:attributes) { { concept: " " } }

    it { expect(entry.errors).to be_added(:concept, :blank) }
  end

  context "with an amount of 0" do
    let(:attributes) { { amount: "0" } }

    it { expect(entry.errors).to be_added(:amount, :greater_than, value: 0, count: 0) }
  end

  context "before the shop started" do
    let(:attributes) { { occurred_on: "2026-09-30" } }

    it { expect(entry.errors).to be_added(:occurred_on, :greater_than_or_equal_to, value: Date.new(2026, 9, 30), count: Date.new(2026, 10, 1)) }
  end

  context "after today" do
    let(:attributes) { { occurred_on: "2026-10-21" } }

    it { expect(entry.errors).to be_added(:occurred_on, :less_than_or_equal_to, value: Date.new(2026, 10, 21), count: Date.new(2026, 10, 20)) }
  end

  context "of a kind that isn't an expense or other income" do
    let(:attributes) { { kind: "loan" } }

    it { expect(entry.errors).to be_added(:kind, :inclusion, value: "loan") }
  end

  context "when saved past its validations with an amount of 0" do
    let(:attributes) { { amount: "0" } }

    it { expect { entry.save(validate: false) }.to raise_error(ActiveRecord::CheckViolation) }
  end

  describe ".latest" do
    subject(:latest) { described_class.latest }

    before do
      create(:entry, shop:, occurred_on: Date.new(2026, 10, 3), concept: "Transporte")
      create(:entry, shop:, occurred_on: Date.new(2026, 10, 14), concept: "Mantenimiento de la fileteadora")
      create(:entry, shop:, occurred_on: Date.new(2026, 10, 3), concept: "Tijeras nuevas")
    end

    it("puts the latest day first, and the last recorded first within a day") { expect(latest.map(&:concept)).to eq([ "Mantenimiento de la fileteadora", "Tijeras nuevas", "Transporte" ]) }
    it { expect(latest.limit_value).to eq(10) }
  end
end
