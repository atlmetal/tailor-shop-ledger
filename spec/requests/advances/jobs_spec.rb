require "rails_helper"

RSpec.describe "Advance jobs", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  let(:advance) { create(:advance, shop:, customer_name: "Hotel Almendros").tap { create(:top_up, advance: it, amount: 109_000) } }
  let(:service) { create(:service, shop:, name: "Forro de chaqueta", price: 35_000, material_cost: 6_000) }
  let(:outsider) { create(:advance).tap { create(:job, advance: it, service: create(:service, shop: it.shop)) } }
  let(:outsider_job) { ActsAsTenant.with_tenant(outsider.shop) { outsider.jobs.sole } }
  let(:balance) { response.parsed_body.at("[data-job-form-target='balance']") }

  before { travel_to Date.new(2026, 10, 20) }

  describe "GET /advances/:advance_id/jobs/new" do
    before do
      service
      get new_advance_job_path(advance)
    end

    it("asks for the date, today by default") { expect(response.parsed_body.at("input[name='job[done_on]']")["value"]).to eq("2026-10-20") }
    it { expect(response.parsed_body.at("legend").text).to eq("Which service did you do for them?") }
    it { expect(response.parsed_body.at("form")["action"]).to eq(advance_jobs_path(advance)) }
    it("starts from the advance's balance") { expect(balance["data-balance"]).to eq("109000") }
    it { expect(balance.text.squish).to start_with("Advance balance $109,000 This job $0 Would still have $109,000") }
    it("hides the debt while the balance covers the job") { expect(balance.at("[data-job-form-target='debt']")["hidden"]).to be_present }
    it("marks Today in the tab bar") { expect(response.parsed_body.at(".tab[aria-current='page']").text.squish).to eq("Today") }
  end

  describe "GET /advances/:advance_id/jobs/new after saving another" do
    before { get new_advance_job_path(advance, done_on: "2026-10-13", service_id: service.id) }

    it("keeps the date") { expect(response.parsed_body.at("input[name='job[done_on]']")["value"]).to eq("2026-10-13") }
    it("keeps the service") { expect(response.parsed_body.at("input[name='job[service_id]'][checked]")["value"]).to eq(service.id.to_s) }
    it { expect(balance.text.squish).to include("This job −$35,000 Would still have $74,000") }
  end

  describe "GET /advances/:advance_id/jobs/new past the balance" do
    before do
      create(:job, advance:, service:, quantity: 4)
      get new_advance_job_path(advance)
    end

    it { expect(balance.at("[data-job-form-target='left']")["hidden"]).to be_present }
    it { expect(balance.at("[data-job-form-target='debt']").text.squish).to eq("The customer would owe $31,000.") }
    it { expect(balance.at("[data-job-form-target='debt']")["hidden"]).to be_nil }
  end

  describe "GET /advances/:advance_id/jobs/new of another shop's advance" do
    before { get new_advance_job_path(outsider) }

    it_behaves_like "a record of another shop"
  end

  describe "POST /advances/:advance_id/jobs" do
    let(:job_params) { { done_on: "2026-10-13", service_id: service.id, quantity: "4", price: "35,000", material_cost: "6,000" } }

    before { post advance_jobs_path(advance), params: { job: job_params } }

    it { expect(response).to redirect_to(advance_path(advance)) }
    it("keeps its own day") { expect(Job.sole).to have_attributes(advance:, service:, done_on: Date.new(2026, 10, 13), quantity: 4, price: 35_000) }
    it("can take more than the balance, and the customer owes the rest") { expect(advance.balance).to eq(-31_000) }

    context "with a date after today" do
      let(:job_params) { super().merge(done_on: "2026-10-21") }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(Job.count).to eq(0) }
    end
  end

  describe "POST /advances/:advance_id/jobs to add another" do
    before { post advance_jobs_path(advance), params: { another: "1", job: { done_on: "2026-10-13", service_id: service.id, quantity: "2", price: "35,000", material_cost: "6,000" } } }

    it { expect(response).to redirect_to(new_advance_job_path(advance, done_on: "2026-10-13", service_id: service.id)) }
    it { expect(flash[:saved]).to eq("2 × Forro de chaqueta, $70,000") }
  end

  describe "POST /advances/:advance_id/jobs to another shop's advance" do
    before { post advance_jobs_path(outsider), params: { job: { done_on: "2026-10-20", service_id: service.id, quantity: "1" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.jobs.count }).to eq(1) }
  end

  describe "GET /advances/:advance_id/jobs/:id/edit" do
    before { get edit_advance_job_path(advance, create(:job, advance:, service:, quantity: 2)) }

    it("leaves the job out of the balance") { expect(balance.text.squish).to start_with("Advance balance $109,000 This job −$70,000 Would still have $39,000") }
    it("cancels back to the advance") { expect(response.parsed_body.at("a:contains('Cancel')")["href"]).to eq(advance_path(advance)) }
  end

  describe "GET /advances/:advance_id/jobs/:id/edit through another of the shop's advances" do
    before { get edit_advance_job_path(create(:advance, shop:, customer_name: "Lucía Restrepo"), create(:job, advance:, service:)) }

    it { expect(response).to have_http_status(:not_found) }
  end

  describe "GET /jobs/:id/edit of a job in an advance" do
    before { get edit_job_path(create(:job, advance:, service:)) }

    it("finds it only under its advance") { expect(response).to have_http_status(:not_found) }
  end

  describe "GET /advances/:advance_id/jobs/:id/edit of another shop" do
    before { get edit_advance_job_path(outsider, outsider_job) }

    it_behaves_like "a record of another shop"
  end

  describe "PATCH /advances/:advance_id/jobs/:id" do
    let(:job) { create(:job, advance:, service:, quantity: 1) }

    before { patch advance_job_path(advance, job), params: { job: { quantity: "2", done_on: "2026-10-12" } } }

    it { expect(response).to redirect_to(advance_path(advance)) }
    it { expect(job.reload).to have_attributes(quantity: 2, done_on: Date.new(2026, 10, 12)) }
  end

  describe "PATCH /advances/:advance_id/jobs/:id of another shop" do
    before { patch advance_job_path(outsider, outsider_job), params: { job: { quantity: "3" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider_job.reload.quantity }).to eq(1) }
  end

  describe "DELETE /advances/:advance_id/jobs/:id" do
    let(:job) { create(:job, advance:, service:) }

    before { delete advance_job_path(advance, job) }

    it { expect(response).to redirect_to(advance_path(advance)) }
    it { expect(Job.exists?(job.id)).to be(false) }
  end

  describe "DELETE /advances/:advance_id/jobs/:id of another shop" do
    before { delete advance_job_path(outsider, outsider_job) }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { Job.exists?(outsider_job.id) }).to be(true) }
  end
end
