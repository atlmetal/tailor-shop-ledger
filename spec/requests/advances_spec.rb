require "rails_helper"

RSpec.describe "Advances", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  let(:advance) { create(:advance, shop:, customer_name: "Hotel Almendros") }

  before { travel_to Date.new(2026, 10, 20) }

  describe "GET /advances/new" do
    before { get new_advance_path }

    it { expect(response.parsed_body.at("label[for='advance_customer_name']").text).to eq("Whose advance is it?") }
    it("marks Today in the tab bar") { expect(response.parsed_body.at(".tab[aria-current='page']").text.squish).to eq("Today") }
    it("cancels back to Today") { expect(response.parsed_body.at("a:contains('Cancel')")["href"]).to eq(root_path) }
  end

  describe "POST /advances" do
    let(:customer_name) { " Hotel  Almendros " }
    let(:existing) { nil }

    before do
      existing
      post advances_path, params: { advance: { customer_name: } }
    end

    it("goes on to its first top-up") { expect(response).to redirect_to(new_advance_top_up_path(Advance.sole)) }
    it { expect(Advance.sole.customer_name).to eq("Hotel Almendros") }

    context "for a customer who already has one" do
      let(:customer_name) { "hotel almendros" }
      let(:existing) { advance }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(response.parsed_body.at(".field-error").text).to eq("Name is already used by another advance") }
    end
  end

  describe "GET /advances/:id" do
    let(:lining) { create(:service, shop:, name: "Forro de chaqueta", price: 35_000, material_cost: 6_000) }

    before do
      create(:top_up, advance:, paid_on: Date.new(2026, 10, 1), amount: 300_000)
      create(:top_up, advance:, paid_on: Date.new(2026, 10, 16), amount: 100_000)
      create(:job, advance:, service: lining, done_on: Date.new(2026, 10, 3), quantity: 2)
      create(:job, advance:, service: lining, done_on: Date.new(2026, 10, 19), quantity: 4)
      get advance_path(advance)
    end

    let(:job_rows) { response.parsed_body.css("[aria-labelledby='advance-jobs'] a").map { it.text.squish } }

    it { expect(response.parsed_body.at("h1").text).to eq("Hotel Almendros") }
    it { expect(response.parsed_body.text.squish).to include("Advance since October 1 Edit") }
    it { expect(response.parsed_body.at("section[aria-label='Advance balance']").text.squish).to eq("Still has $190,000 Gave you $400,000, and you've done $210,000 in jobs for them.") }
    it("lists its jobs, the most recent first, each with its date") { expect(job_rows).to eq([ "4 × Forro de chaqueta October 19 $140,000", "2 × Forro de chaqueta October 3 $70,000" ]) }
    it("opens each job under the advance") { expect(response.parsed_body.at("a:contains('4 × Forro de chaqueta')")["href"]).to eq(edit_advance_job_path(advance, advance.jobs.first)) }
    it { expect(response.parsed_body.text.squish).to include("Jobs 6 jobs") }
    it("lists its top-ups, the most recent first") { expect(response.parsed_body.css("[aria-labelledby='advance-top-ups'] a").map { it.text.squish }).to eq([ "Friday, October 16 $100,000", "Thursday, October 1 $300,000" ]) }
    it { expect(response.parsed_body.at("a:contains('Record a top-up')")["href"]).to eq(new_advance_top_up_path(advance)) }
    it("marks Today in the tab bar") { expect(response.parsed_body.at(".tab[aria-current='page']").text.squish).to eq("Today") }

    context "once its jobs charge more than the customer gave" do
      before do
        create(:job, advance:, service: lining, done_on: Date.new(2026, 10, 20), quantity: 6)
        get advance_path(advance)
      end

      it { expect(response.parsed_body.at("section[aria-label='Advance balance']").text.squish).to start_with("Owes you $20,000") }
    end
  end

  describe "GET /advances/:id without top-ups or jobs yet" do
    before { get advance_path(advance) }

    it { expect(response.parsed_body.at("section[aria-label='Advance balance']").text.squish).to start_with("Still has $0") }
    it { expect(response.parsed_body.text.squish).to include("No jobs for them yet.", "They haven't given you any money yet.") }
  end

  describe "GET /advances/:id of another shop" do
    before { get advance_path(create(:advance)) }

    it_behaves_like "a record of another shop"
  end

  describe "GET /advances/:id/edit" do
    before { get edit_advance_path(advance) }

    it { expect(response.parsed_body.at("h1").text).to eq("Edit name") }
    it("cancels back to the advance") { expect(response.parsed_body.at("a:contains('Cancel')")["href"]).to eq(advance_path(advance)) }
    it { expect(response.parsed_body.at("button:contains('Delete advance')")).to be_present }

    context "with jobs" do
      before do
        create(:job, advance:, service: create(:service, shop:))
        get edit_advance_path(advance)
      end

      it("can't be deleted") { expect(response.parsed_body.at("button:contains('Delete advance')")).to be_nil }
    end
  end

  describe "PATCH /advances/:id" do
    before { patch advance_path(advance), params: { advance: { customer_name: "Hotel Los Almendros" } } }

    it { expect(response).to redirect_to(advance_path(advance)) }
    it { expect(advance.reload.customer_name).to eq("Hotel Los Almendros") }
  end

  describe "PATCH /advances/:id of another shop" do
    let(:outsider) { create(:advance, customer_name: "Hotel del Parque") }

    before { patch advance_path(outsider), params: { advance: { customer_name: "Hotel Los Almendros" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.reload.customer_name }).to eq("Hotel del Parque") }
  end

  describe "DELETE /advances/:id" do
    before do
      create(:top_up, advance:)
      delete advance_path(advance)
    end

    it { expect(response).to redirect_to(root_path) }
    it("deletes it with its top-ups") { expect([ Advance.count, TopUp.count ]).to eq([ 0, 0 ]) }
  end

  describe "DELETE /advances/:id with jobs" do
    before do
      create(:job, advance:, service: create(:service, shop:))
      delete advance_path(advance)
    end

    it { expect(response).to have_http_status(:unprocessable_content) }
    it { expect(response.parsed_body.at(".field-error").text).to eq("It has jobs, so it can't be deleted.") }
    it { expect(Advance.exists?(advance.id)).to be(true) }
  end

  describe "DELETE /advances/:id of another shop" do
    let(:outsider) { create(:advance) }

    before { delete advance_path(outsider) }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { Advance.exists?(outsider.id) }).to be(true) }
  end
end
