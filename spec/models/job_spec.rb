require "rails_helper"

RSpec.describe Job, type: :model do
  include_context "with a current shop"

  subject(:job) { described_class.new(service:, done_on: "2026-10-20", quantity: 2, **attributes) }

  let(:shop) { create(:shop, started_on: Date.new(2026, 10, 1)) }
  let(:service) { create(:service, shop:, price: 8_000, material_cost: 500) }
  let(:attributes) { {} }

  before do
    travel_to Date.new(2026, 10, 20)
    job.validate
  end

  it { is_expected.to be_valid }
  it { is_expected.to have_attributes(price: 8_000, material_cost: 500) }
  it { is_expected.to have_attributes(charged: 16_000, materials: 1_000, leaves: 15_000) }

  context "with a price and materials of its own" do
    let(:attributes) { { price: "9,500", material_cost: "0" } }

    it { is_expected.to have_attributes(price: 9_500, material_cost: 0) }
  end

  context "when its service changes after it was recorded" do
    before do
      job.save!
      service.update!(price: 9_000, material_cost: 700)
    end

    it { expect(job.reload).to have_attributes(price: 8_000, material_cost: 500) }
  end

  context "on the day the shop started" do
    let(:attributes) { { done_on: "2026-10-01" } }

    it { is_expected.to be_valid }
  end

  context "before the shop started" do
    let(:attributes) { { done_on: "2026-09-30" } }

    it { expect(job.errors).to be_added(:done_on, :greater_than_or_equal_to, value: Date.new(2026, 9, 30), count: Date.new(2026, 10, 1)) }
  end

  context "after today" do
    let(:attributes) { { done_on: "2026-10-21" } }

    it { expect(job.errors).to be_added(:done_on, :less_than_or_equal_to, value: Date.new(2026, 10, 21), count: Date.new(2026, 10, 20)) }
  end

  context "without a quantity" do
    let(:attributes) { { quantity: 0 } }

    it { expect(job.errors).to be_added(:quantity, :greater_than_or_equal_to, value: 0, count: 1) }
  end

  context "with a negative price" do
    let(:attributes) { { price: -1 } }

    it { expect(job.errors).to be_added(:price, :greater_than_or_equal_to, value: -1, count: 0) }
  end

  context "with another shop's service" do
    let(:service) { create(:service) }

    it { expect(job.errors).to be_added(:service_id, :"acts_as_tenant.association_invalid") }
  end

  context "when saved past its validations without a quantity" do
    let(:attributes) { { quantity: 0 } }

    it { expect { job.save(validate: false) }.to raise_error(ActiveRecord::CheckViolation) }
  end

  describe "in an order" do
    let(:order) { create(:order, shop:, received_on: Date.new(2026, 10, 15)) }

    context "whatever date it's given" do
      let(:attributes) { { order: } }

      it("takes the order's day") { expect(job.done_on).to eq(Date.new(2026, 10, 15)) }
    end

    context "with another shop's order" do
      let(:attributes) { { order: create(:order) } }

      it { expect(job.errors).to be_added(:order_id, :"acts_as_tenant.association_invalid") }
    end

    context "when it no longer covers the order's payments" do
      subject(:job) { create(:job, order:, service:, quantity: 2) }

      before do
        create(:payment, order:, amount: 12_000)
        job.quantity = 1
        job.validate
      end

      it { expect(job.errors).to be_added(:base, :less_than_paid) }
    end

    context "when deleting it would leave the order's payments uncovered" do
      subject(:job) { create(:job, order:, service:, quantity: 2) }

      before do
        create(:payment, order:, amount: 12_000)
        job.destroy
      end

      it { expect(described_class.exists?(job.id)).to be(true) }
      it { expect(job.errors).to be_added(:base, :less_than_paid) }
    end

    context "when the order's other jobs cover its payments" do
      subject(:job) { create(:job, order:, service:, quantity: 2) }

      before do
        create(:job, order:, service:, quantity: 2)
        create(:payment, order:, amount: 16_000)
        job.destroy
      end

      it("can be deleted") { expect(described_class.exists?(job.id)).to be(false) }
    end
  end
end
