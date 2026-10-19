require "rails_helper"

RSpec.describe OrdersHelper, type: :helper do
  let(:order) do
    instance_double(Order, to_param: "3", customer_name: "Marta Rodríguez", received_on: Date.new(2026, 10, 15), jobs:, payments:, total: 39_000, paid: 20_000, owed:)
  end
  let(:jobs) { [ instance_double(Job, quantity: 3), instance_double(Job, quantity: 1) ] }
  let(:payments) { [] }
  let(:owed) { 19_000 }

  describe "#order_received_on" do
    it { expect(helper.order_received_on(order)).to eq("Left on Thursday, October 15") }
  end

  describe "#order_link" do
    it { expect(helper.order_link(order)).to have_link("Order for Marta Rodríguez", href: "/orders/3") }
  end

  describe "#order_summary" do
    it { expect(helper.order_summary(order)).to have_text("Owes you $19,000 Has paid you $20,000 of $39,000.", normalize_ws: true) }

    context "once paid off" do
      let(:owed) { 0 }

      it { expect(helper.order_summary(order)).to have_text("Paid off $39,000 Paid you the whole order.", normalize_ws: true) }
    end

    context "without jobs yet" do
      let(:jobs) { [] }

      it { expect(helper.order_summary(order)).to be_nil }
    end
  end

  describe "#record_payment_button" do
    it { expect(helper.record_payment_button(order)).to have_link("Record a payment", href: "/orders/3/payments/new") }

    context "once paid off" do
      let(:owed) { 0 }

      it { expect(helper.record_payment_button(order)).to be_nil }
    end
  end

  describe "#order_units" do
    it { expect(helper.order_units(order)).to eq("4 jobs") }

    context "without jobs yet" do
      let(:jobs) { [] }

      it { expect(helper.order_units(order)).to be_nil }
    end
  end

  describe "#add_job_class" do
    it { expect(helper.add_job_class(order)).to include("btn-secondary") }

    context "without jobs yet" do
      let(:jobs) { [] }

      it("makes adding one the next step") { expect(helper.add_job_class(order)).to include("btn-primary") }
    end
  end

  describe "#order_jobs" do
    let(:jobs) { [] }

    it { expect(helper.order_jobs(order)).to have_text("Add what they left you: one job for each service.") }
  end

  describe "#order_payments" do
    it { expect(helper.order_payments(order)).to have_text("No payments yet.") }

    context "with a payment" do
      let(:payments) { [ instance_double(Payment, order: instance_double(Order, to_param: "3"), to_param: "5", paid_on: Date.new(2026, 10, 15), amount: 20_000) ] }

      it { expect(helper.order_payments(order)).to have_link("Thursday, October 15 $20,000", href: "/orders/3/payments/5/edit", normalize_ws: true) }
    end
  end

  describe "#payment_owed_hint" do
    it { expect(helper.payment_owed_hint(instance_double(Payment, new_record?: true, owed: 19_000))).to eq("Owes you $19,000.") }
    it { expect(helper.payment_owed_hint(instance_double(Payment, new_record?: false, owed: 39_000))).to eq("Without this payment, owes you $39,000.") }
  end
end
