require "rails_helper"

RSpec.describe Order, type: :model do
  include_context "with a current shop"

  subject(:order) { described_class.new(customer_name: "Marta Rodríguez", received_on: "2026-10-15", **attributes) }

  let(:shop) { create(:shop, started_on: Date.new(2026, 10, 1)) }
  let(:attributes) { {} }

  before do
    travel_to Date.new(2026, 10, 20)
    order.validate
  end

  it { is_expected.to be_valid }

  context "with spaces around and inside the customer's name" do
    let(:attributes) { { customer_name: "  Marta   Rodríguez " } }

    it { expect(order.customer_name).to eq("Marta Rodríguez") }
  end

  context "without the customer's name" do
    let(:attributes) { { customer_name: " " } }

    it { expect(order.errors).to be_added(:customer_name, :blank) }
  end

  context "with a name over 60 characters" do
    let(:attributes) { { customer_name: "M" * 61 } }

    it { expect(order.errors).to be_added(:customer_name, :too_long, count: 60) }
  end

  context "on the day the shop started" do
    let(:attributes) { { received_on: "2026-10-01" } }

    it { is_expected.to be_valid }
  end

  context "before the shop started" do
    let(:attributes) { { received_on: "2026-09-30" } }

    it { expect(order.errors).to be_added(:received_on, :greater_than_or_equal_to, value: Date.new(2026, 9, 30), count: Date.new(2026, 10, 1)) }
  end

  context "after today" do
    let(:attributes) { { received_on: "2026-10-21" } }

    it { expect(order.errors).to be_added(:received_on, :less_than_or_equal_to, value: Date.new(2026, 10, 21), count: Date.new(2026, 10, 20)) }
  end

  describe "what it charges and what's owed" do
    subject(:recorded) { order.reload }

    let(:order) { create(:order, shop:, received_on: Date.new(2026, 10, 15)) }

    context "without jobs yet" do
      it { is_expected.to have_attributes(total: 0, paid: 0, owed: 0) }
      it { is_expected.to be_pending }
    end

    context "with jobs and a deposit" do
      before do
        create(:job, order:, service: create(:service, shop:, price: 8_000), quantity: 3)
        create(:job, order:, service: create(:service, shop:, price: 25_000))
        create(:payment, order:, amount: 20_000)
      end

      it { is_expected.to have_attributes(total: 49_000, paid: 20_000, owed: 29_000) }
      it { is_expected.to be_pending }

      context "when the rest is paid" do
        before { create(:payment, order:, paid_on: Date.new(2026, 10, 20), amount: 29_000) }

        it { is_expected.to have_attributes(owed: 0) }
        it { is_expected.not_to be_pending }
      end
    end
  end

  context "when its day moves" do
    let(:order) { create(:order, shop:, received_on: Date.new(2026, 10, 15)) }
    let!(:job) { create(:job, order:, service: create(:service, shop:)) }

    before { order.update!(received_on: Date.new(2026, 10, 14)) }

    it("moves its jobs with it") { expect(job.reload.done_on).to eq(Date.new(2026, 10, 14)) }
  end

  context "when its day moves past its first payment" do
    let(:order) { create(:order, :with_job, shop:, received_on: Date.new(2026, 10, 15)) }

    before do
      create(:payment, order:, paid_on: Date.new(2026, 10, 16), amount: 5_000)
      order.received_on = Date.new(2026, 10, 17)
      order.validate
    end

    it { expect(order.errors).to be_added(:received_on, :after_payments) }
  end

  context "when deleted" do
    let(:order) { create(:order, :with_job, shop:, received_on: Date.new(2026, 10, 15)) }

    before do
      create(:payment, order:)
      order.destroy!
    end

    it("deletes its jobs") { expect(Job.count).to eq(0) }
    it("deletes its payments") { expect(Payment.count).to eq(0) }
  end
end
