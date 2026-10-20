require "rails_helper"

RSpec.describe TopUp, type: :model do
  include_context "with a current shop"

  subject(:top_up) { advance.top_ups.new(paid_on: "2026-10-20", amount: "100,000", **attributes) }

  let(:shop) { create(:shop, started_on: Date.new(2026, 10, 1)) }
  let(:advance) { create(:advance, shop:) }
  let(:attributes) { {} }

  before do
    travel_to Date.new(2026, 10, 20)
    top_up.validate
  end

  it { is_expected.to be_valid }
  it { expect(top_up.amount).to eq(100_000) }

  context "with an amount of 0" do
    let(:attributes) { { amount: "0" } }

    it { expect(top_up.errors).to be_added(:amount, :greater_than, value: 0, count: 0) }
  end

  context "on the day the shop started" do
    let(:attributes) { { paid_on: "2026-10-01" } }

    it { is_expected.to be_valid }
  end

  context "before the shop started" do
    let(:attributes) { { paid_on: "2026-09-30" } }

    it { expect(top_up.errors).to be_added(:paid_on, :greater_than_or_equal_to, value: Date.new(2026, 9, 30), count: Date.new(2026, 10, 1)) }
  end

  context "after today" do
    let(:attributes) { { paid_on: "2026-10-21" } }

    it { expect(top_up.errors).to be_added(:paid_on, :less_than_or_equal_to, value: Date.new(2026, 10, 21), count: Date.new(2026, 10, 20)) }
  end

  describe "the advance's balance" do
    let(:advance) do
      create(:advance, shop:).tap do
        create(:top_up, advance: it, amount: 50_000)
        create(:job, advance: it, service: create(:service, shop:, price: 70_000))
      end
    end

    it { expect(top_up.advance_balance).to eq(-20_000) }

    context "when a recorded top-up changes" do
      subject(:top_up) { advance.top_ups.first.tap { it.amount = 80_000 } }

      it("leaves its own amount out") { expect(top_up.advance_balance).to eq(-70_000) }
    end
  end

  context "with another shop's advance" do
    subject(:top_up) { described_class.new(advance: create(:advance), paid_on: "2026-10-20", amount: "100,000") }

    it { expect(top_up.errors).to be_added(:advance_id, :"acts_as_tenant.association_invalid") }
  end

  context "when saved past its validations with an amount of 0" do
    let(:attributes) { { amount: "0" } }

    it { expect { top_up.save(validate: false) }.to raise_error(ActiveRecord::CheckViolation) }
  end
end
