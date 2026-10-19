require "rails_helper"

RSpec.describe "Order payments", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  let(:order) { create(:order, shop:, received_on: Date.new(2026, 10, 15)).tap { create(:job, order: it, service: create(:service, shop:, price: 49_000)) } }
  let(:outsider) { create(:order, :with_job) }
  let(:outsider_payment) { create(:payment, order: outsider, amount: 20_000) }

  before { travel_to Date.new(2026, 10, 20) }

  describe "GET /orders/:order_id/payments/new" do
    before { get new_order_payment_path(order) }

    it("starts the first payment empty") { expect(response.parsed_body.at("input[name='payment[amount]']")["value"]).to be_blank }
    it { expect(response.parsed_body.at("input[name='payment[paid_on]']")["value"]).to eq("2026-10-20") }
    it("can't be before the order's day") { expect(response.parsed_body.at("input[name='payment[paid_on]']")["min"]).to eq("2026-10-15") }
    it { expect(response.parsed_body.at(".form-hint").text).to eq("Owes you $49,000.") }
  end

  describe "GET /orders/:order_id/payments/new after a deposit" do
    before do
      create(:payment, order:, amount: 20_000)
      get new_order_payment_path(order)
    end

    it("starts with what's still owed") { expect(response.parsed_body.at("input[name='payment[amount]']")["value"]).to eq("29,000") }
  end

  describe "GET /orders/:order_id/payments/new of another shop's order" do
    before { get new_order_payment_path(outsider) }

    it_behaves_like "a record of another shop"
  end

  describe "POST /orders/:order_id/payments" do
    let(:amount) { "20,000" }

    before { post order_payments_path(order), params: { payment: { paid_on: "2026-10-15", amount: } } }

    it { expect(response).to redirect_to(order_path(order)) }
    it { expect(Payment.sole).to have_attributes(order:, paid_on: Date.new(2026, 10, 15), amount: 20_000) }

    context "for more than the order owes" do
      let(:amount) { "50,000" }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(response.parsed_body.at(".field-error").text).to eq("Amount is more than the order owes") }
    end
  end

  describe "POST /orders/:order_id/payments to another shop's order" do
    before { post order_payments_path(outsider), params: { payment: { paid_on: "2026-10-20", amount: "20,000" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.payments.count }).to eq(0) }
  end

  describe "GET /orders/:order_id/payments/:id/edit" do
    before { get edit_order_payment_path(order, create(:payment, order:, amount: 20_000)) }

    it { expect(response.parsed_body.at(".form-hint").text).to eq("Without this payment, owes you $49,000.") }
    it("cancels back to the order") { expect(response.parsed_body.at("a:contains('Cancel')")["href"]).to eq(order_path(order)) }
  end

  describe "GET /orders/:order_id/payments/:id/edit of another shop" do
    before { get edit_order_payment_path(outsider, outsider_payment) }

    it_behaves_like "a record of another shop"
  end

  describe "PATCH /orders/:order_id/payments/:id" do
    let(:payment) { create(:payment, order:, amount: 20_000) }

    before { patch order_payment_path(order, payment), params: { payment: { amount: "25,000" } } }

    it { expect(response).to redirect_to(order_path(order)) }
    it { expect(payment.reload.amount).to eq(25_000) }
  end

  describe "PATCH /orders/:order_id/payments/:id of another shop" do
    before { patch order_payment_path(outsider, outsider_payment), params: { payment: { amount: "25,000" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider_payment.reload.amount }).to eq(20_000) }
  end

  describe "DELETE /orders/:order_id/payments/:id" do
    let(:payment) { create(:payment, order:) }

    before { delete order_payment_path(order, payment) }

    it { expect(response).to redirect_to(order_path(order)) }
    it { expect(Payment.exists?(payment.id)).to be(false) }
  end

  describe "DELETE /orders/:order_id/payments/:id of another shop" do
    before { delete order_payment_path(outsider, outsider_payment) }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { Payment.exists?(outsider_payment.id) }).to be(true) }
  end
end
