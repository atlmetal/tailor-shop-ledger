require "rails_helper"

RSpec.describe "Jobs", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  let(:service) { create(:service, shop:, name: "Basta de pantalón", price: 8_000, material_cost: 500) }

  before { travel_to Date.new(2026, 10, 20) }

  describe "GET /jobs/new" do
    before do
      service
      create(:service, shop:, name: "Cortinas", active: false)
      create(:service, name: "Bordado de enfrente")
      get new_job_path
    end

    it { expect(response.parsed_body.css(".service-option").map { it.text.squish }).to eq([ "Basta de pantalón $8,000" ]) }
    it { expect(response.parsed_body.at("input[name='job[done_on]']")["value"]).to eq("2026-10-20") }
    it { expect(response.parsed_body.at("input[name='job[service_id]'][checked]")).to be_nil }
  end

  describe "GET /jobs/new after saving another" do
    before { get new_job_path(done_on: "2026-10-13", service_id: service.id) }

    it { expect(response.parsed_body.at("input[name='job[done_on]']")["value"]).to eq("2026-10-13") }
    it { expect(response.parsed_body.at("input[name='job[service_id]'][checked]")["value"]).to eq(service.id.to_s) }
    it { expect(response.parsed_body.at("input[name='job[price]']")["value"]).to eq("8,000") }
    it { expect(response.parsed_body.at("input[name='job[quantity]']")["value"]).to eq("1") }
  end

  describe "POST /jobs" do
    let(:job_params) { { done_on: "2026-10-20", service_id: service.id, quantity: "2", price: "8,000", material_cost: "500" } }

    before { post jobs_path, params: { job: job_params } }

    it { expect(response).to redirect_to(root_path) }
    it { expect(Job.sole).to have_attributes(service:, done_on: Date.new(2026, 10, 20), quantity: 2, price: 8_000, material_cost: 500) }

    context "with a price of its own" do
      let(:job_params) { super().merge(price: "10,000") }

      it { expect(Job.sole.price).to eq(10_000) }
    end

    context "without a service" do
      let(:job_params) { super().except(:service_id) }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(response.parsed_body.at("fieldset .field-error").text).to eq("Service isn't chosen") }
    end

    context "with another shop's service" do
      let(:job_params) { super().merge(service_id: create(:service).id) }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(Job.count).to eq(0) }
    end
  end

  describe "GET /jobs/:id/edit" do
    let(:job) { create(:job, service:) }

    before do
      job
      service.update!(active: false)
      create(:service, shop:, name: "Cambio de cremallera")
      get edit_job_path(job)
    end

    it("offers the job's service though it was deactivated") { expect(response.parsed_body.css(".service-option .font-semibold").map(&:text)).to eq([ "Basta de pantalón", "Cambio de cremallera" ]) }
    it { expect(response.parsed_body.at("input[name='job[service_id]'][checked]")["value"]).to eq(service.id.to_s) }
  end

  describe "GET /jobs/:id/edit of another shop" do
    before { get edit_job_path(create(:job)) }

    it_behaves_like "a record of another shop"
  end

  describe "PATCH /jobs/:id" do
    let(:job) { create(:job, service:, quantity: 1) }

    before { patch job_path(job), params: { job: { quantity: "3" } } }

    it { expect(response).to redirect_to(root_path) }
    it { expect(job.reload.quantity).to eq(3) }
  end

  describe "PATCH /jobs/:id of another shop" do
    let(:outsider) { create(:job, quantity: 1) }

    before { patch job_path(outsider), params: { job: { quantity: "3" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.reload.quantity }).to eq(1) }
  end

  describe "DELETE /jobs/:id" do
    let(:job) { create(:job, service:) }

    before { delete job_path(job) }

    it { expect(response).to redirect_to(root_path) }
    it { expect(Job.exists?(job.id)).to be(false) }
  end

  describe "DELETE /jobs/:id of another shop" do
    let(:outsider) { create(:job) }

    before { delete job_path(outsider) }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { Job.exists?(outsider.id) }).to be(true) }
  end

  describe "POST /jobs to record another" do
    before { post jobs_path, params: { another: "1", job: { done_on: "2026-10-13", service_id: service.id, quantity: "2", price: "8,000", material_cost: "500" } } }

    it { expect(response).to redirect_to(new_job_path(done_on: "2026-10-13", service_id: service.id)) }
    it { expect(flash[:saved]).to eq("2 × Basta de pantalón, $16,000") }
  end
end
