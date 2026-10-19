require "rails_helper"

RSpec.describe "Orders", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  let(:order) { create(:order, shop:, customer_name: "Marta Rodríguez", received_on: Date.new(2026, 10, 15)) }

  before { travel_to Date.new(2026, 10, 20) }

  describe "GET /orders/new" do
    before { get new_order_path }

    it { expect(response.parsed_body.at("input[name='order[received_on]']")["value"]).to eq("2026-10-20") }
    it("marks Order in Record's switch") { expect(response.parsed_body.at(".switch a[aria-current='page']").text).to eq("Order") }
  end

  describe "POST /orders" do
    let(:order_params) { { customer_name: " Marta  Rodríguez ", received_on: "2026-10-15" } }

    before { post orders_path, params: { order: order_params } }

    it("goes on to its first job") { expect(response).to redirect_to(new_order_job_path(Order.sole)) }
    it { expect(Order.sole).to have_attributes(customer_name: "Marta Rodríguez", received_on: Date.new(2026, 10, 15)) }

    context "without the customer's name" do
      let(:order_params) { super().merge(customer_name: "") }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(response.parsed_body.at(".field-error").text).to eq("Name can't be blank") }
    end
  end

  describe "GET /orders/:id" do
    let(:hem) { create(:service, shop:, name: "Basta de pantalón", price: 8_000, material_cost: 500) }

    before do
      create(:job, order:, service: hem, quantity: 3)
      create(:payment, order:, paid_on: Date.new(2026, 10, 15), amount: 10_000)
      get order_path(order)
    end

    it { expect(response.parsed_body.at("h1").text).to eq("Marta Rodríguez") }
    it { expect(response.parsed_body.at("section[aria-label=\"What's owed\"]").text.squish).to eq("Owes you $14,000 Has paid you $10,000 of $24,000.") }
    it { expect(response.parsed_body.at("a:contains('Record a payment')")["href"]).to eq(new_order_payment_path(order)) }
    it("opens each job under the order") { expect(response.parsed_body.at("a:contains('3 × Basta de pantalón')")["href"]).to eq(edit_order_job_path(order, Job.sole)) }
    it("opens each payment") { expect(response.parsed_body.at("a:contains('Thursday, October 15')")["href"]).to eq(edit_order_payment_path(order, Payment.sole)) }

    context "once paid off" do
      before do
        create(:payment, order:, paid_on: Date.new(2026, 10, 20), amount: 14_000)
        get order_path(order)
      end

      it { expect(response.parsed_body.at("section[aria-label=\"What's owed\"]").text.squish).to eq("Paid off $24,000 Paid you the whole order.") }
      it { expect(response.parsed_body.at("a:contains('Record a payment')")).to be_nil }
    end
  end

  describe "GET /orders/:id without jobs yet" do
    before { get order_path(order) }

    it { expect(response.parsed_body.at("section[aria-label=\"What's owed\"]")).to be_nil }
    it { expect(response.parsed_body.at("a:contains('Add a job')")["href"]).to eq(new_order_job_path(order)) }
  end

  describe "GET /orders/:id of another shop" do
    before { get order_path(create(:order)) }

    it_behaves_like "a record of another shop"
  end

  describe "PATCH /orders/:id" do
    let(:received_on) { "2026-10-14" }

    before { patch order_path(order), params: { order: { customer_name: "Marta R.", received_on: } } }

    it { expect(response).to redirect_to(order_path(order)) }
    it { expect(order.reload).to have_attributes(customer_name: "Marta R.", received_on: Date.new(2026, 10, 14)) }

    context "with a date after today" do
      let(:received_on) { "2026-10-21" }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it("cancels back to the order") { expect(response.parsed_body.at("a:contains('Cancel')")["href"]).to eq(order_path(order)) }
    end
  end

  describe "PATCH /orders/:id of another shop" do
    let(:outsider) { create(:order, customer_name: "Lucía Herrera") }

    before { patch order_path(outsider), params: { order: { customer_name: "Marta R." } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.reload.customer_name }).to eq("Lucía Herrera") }
  end

  describe "DELETE /orders/:id" do
    before do
      create(:job, order:, service: create(:service, shop:, price: 30_000))
      create(:payment, order:, amount: 10_000)
      delete order_path(order)
    end

    it { expect(response).to redirect_to(root_path) }
    it("deletes it with its jobs and payments") { expect([ Order.count, Job.count, Payment.count ]).to eq([ 0, 0, 0 ]) }
  end

  describe "DELETE /orders/:id of another shop" do
    let(:outsider) { create(:order) }

    before { delete order_path(outsider) }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { Order.exists?(outsider.id) }).to be(true) }
  end
end
