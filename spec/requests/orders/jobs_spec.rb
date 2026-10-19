require "rails_helper"

RSpec.describe "Order jobs", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  let(:order) { create(:order, shop:, received_on: Date.new(2026, 10, 15)) }
  let(:service) { create(:service, shop:, name: "Basta de pantalón", price: 8_000, material_cost: 500) }
  let(:outsider) { create(:order, :with_job) }
  let(:outsider_job) { ActsAsTenant.with_tenant(outsider.shop) { outsider.jobs.sole } }

  before { travel_to Date.new(2026, 10, 20) }

  describe "GET /orders/:order_id/jobs/new" do
    before do
      service
      get new_order_job_path(order)
    end

    it("asks for no date, since the job takes the order's day") { expect(response.parsed_body.at("input[name='job[done_on]']")).to be_nil }
    it { expect(response.parsed_body.at("legend").text).to eq("Which service did they ask for?") }
    it { expect(response.parsed_body.at("form")["action"]).to eq(order_jobs_path(order)) }
  end

  describe "GET /orders/:order_id/jobs/new of another shop's order" do
    before { get new_order_job_path(outsider) }

    it_behaves_like "a record of another shop"
  end

  describe "POST /orders/:order_id/jobs" do
    before { post order_jobs_path(order), params: { job: { service_id: service.id, quantity: "3", price: "8,000", material_cost: "500" } } }

    it { expect(response).to redirect_to(order_path(order)) }
    it { expect(Job.sole).to have_attributes(order:, service:, done_on: Date.new(2026, 10, 15), quantity: 3, price: 8_000) }
  end

  describe "POST /orders/:order_id/jobs to add another" do
    before { post order_jobs_path(order), params: { another: "1", job: { service_id: service.id, quantity: "2", price: "8,000", material_cost: "500" } } }

    it { expect(response).to redirect_to(new_order_job_path(order, service_id: service.id)) }
    it { expect(flash[:saved]).to eq("2 × Basta de pantalón, $16,000") }
  end

  describe "POST /orders/:order_id/jobs to another shop's order" do
    before { post order_jobs_path(outsider), params: { job: { service_id: service.id, quantity: "1" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.jobs.count }).to eq(1) }
  end

  describe "GET /orders/:order_id/jobs/:id/edit" do
    before { get edit_order_job_path(order, create(:job, order:, service:)) }

    it("cancels back to the order") { expect(response.parsed_body.at("a:contains('Cancel')")["href"]).to eq(order_path(order)) }
  end

  describe "GET /orders/:order_id/jobs/:id/edit through another of the shop's orders" do
    before { get edit_order_job_path(create(:order, shop:), create(:job, order:, service:)) }

    it { expect(response).to have_http_status(:not_found) }
  end

  describe "GET /orders/:order_id/jobs/:id/edit of another shop" do
    before { get edit_order_job_path(outsider, outsider_job) }

    it_behaves_like "a record of another shop"
  end

  describe "PATCH /orders/:order_id/jobs/:id" do
    let(:job) { create(:job, order:, service:, quantity: 1) }

    before { patch order_job_path(order, job), params: { job: { quantity: "2" } } }

    it { expect(response).to redirect_to(order_path(order)) }
    it { expect(job.reload.quantity).to eq(2) }
  end

  describe "PATCH /orders/:order_id/jobs/:id of another shop" do
    before { patch order_job_path(outsider, outsider_job), params: { job: { quantity: "3" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider_job.reload.quantity }).to eq(1) }
  end

  describe "DELETE /orders/:order_id/jobs/:id" do
    let(:job) { create(:job, order:, service:) }

    before { delete order_job_path(order, job) }

    it { expect(response).to redirect_to(order_path(order)) }
    it { expect(Job.exists?(job.id)).to be(false) }
  end

  describe "DELETE /orders/:order_id/jobs/:id while the order's payments need it" do
    let(:job) { create(:job, order:, service:, quantity: 2) }

    before do
      create(:payment, order: job.order, amount: 16_000)
      delete order_job_path(order, job)
    end

    it { expect(response).to have_http_status(:unprocessable_content) }
    it { expect(response.parsed_body.at(".field-error").text).to eq("The order's payments would come to more than its jobs: lower or delete a payment first.") }
    it { expect(Job.exists?(job.id)).to be(true) }
  end

  describe "DELETE /orders/:order_id/jobs/:id of another shop" do
    before { delete order_job_path(outsider, outsider_job) }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { Job.exists?(outsider_job.id) }).to be(true) }
  end
end
