require "rails_helper"

RSpec.describe Payment, type: :model do
  include_context "with a current shop"

  subject(:payment) { order.payments.new(paid_on: "2026-10-20", amount: "20,000", **attributes) }

  let(:shop) { create(:shop, started_on: Date.new(2026, 10, 1)) }
  let(:order) { create(:order, shop:, received_on: Date.new(2026, 10, 15)).tap { create(:job, order: it, service: create(:service, shop:, price: 49_000)) } }
  let(:attributes) { {} }

  before do
    travel_to Date.new(2026, 10, 20)
    payment.validate
  end

  it { is_expected.to be_valid }
  it { expect(payment.amount).to eq(20_000) }

  context "with an amount of 0" do
    let(:attributes) { { amount: "0" } }

    it { expect(payment.errors).to be_added(:amount, :greater_than, value: 0, count: 0) }
  end

  context "on the day the order was left" do
    let(:attributes) { { paid_on: "2026-10-15" } }

    it { is_expected.to be_valid }
  end

  context "before the day the order was left" do
    let(:attributes) { { paid_on: "2026-10-14" } }

    it { expect(payment.errors).to be_added(:paid_on, :greater_than_or_equal_to, value: Date.new(2026, 10, 14), count: Date.new(2026, 10, 15)) }
  end

  context "after today" do
    let(:attributes) { { paid_on: "2026-10-21" } }

    it { expect(payment.errors).to be_added(:paid_on, :less_than_or_equal_to, value: Date.new(2026, 10, 21), count: Date.new(2026, 10, 20)) }
  end

  context "for everything the order owes" do
    let(:attributes) { { amount: "49,000" } }

    it { is_expected.to be_valid }
  end

  context "for more than the order owes" do
    let(:attributes) { { amount: "49,001" } }

    it { expect(payment.errors).to be_added(:amount, :more_than_owed) }
  end

  context "after an earlier payment" do
    let(:order) { super().tap { create(:payment, order: it, amount: 30_000) } }

    it("can't pay more than the rest") { expect(payment.errors).to be_added(:amount, :more_than_owed) }
    it { expect(payment.owed).to eq(19_000) }
  end

  context "when a recorded payment changes" do
    subject(:payment) { create(:payment, order:, amount: 20_000).tap { it.amount = 49_000 } }

    it("leaves its own amount out of what's owed") { is_expected.to be_valid }
  end

  context "with another shop's order" do
    subject(:payment) { described_class.new(order: create(:order, :with_job), paid_on: "2026-10-20", amount: "20,000") }

    it { expect(payment.errors).to be_added(:order_id, :"acts_as_tenant.association_invalid") }
  end

  context "when saved past its validations with an amount of 0" do
    let(:attributes) { { amount: "0" } }

    it { expect { payment.save(validate: false) }.to raise_error(ActiveRecord::CheckViolation) }
  end
end
