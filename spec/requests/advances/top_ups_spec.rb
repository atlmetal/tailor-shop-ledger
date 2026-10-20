require "rails_helper"

RSpec.describe "Advance top-ups", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  let(:user) { create(:user, shop: create(:shop, started_on: Date.new(2026, 10, 1))) }
  let(:advance) { create(:advance, shop:).tap { create(:job, advance: it, service: create(:service, shop:, price: 291_000)) } }
  let(:outsider) { create(:advance) }
  let(:outsider_top_up) { create(:top_up, advance: outsider, amount: 100_000) }

  before { travel_to Date.new(2026, 10, 20) }

  describe "GET /advances/:advance_id/top_ups/new" do
    before do
      create(:top_up, advance:, amount: 400_000)
      get new_advance_top_up_path(advance)
    end

    it { expect(response.parsed_body.at("input[name='top_up[amount]']")["value"]).to be_blank }
    it { expect(response.parsed_body.at("input[name='top_up[paid_on]']")["value"]).to eq("2026-10-20") }
    it("can't be before the shop started") { expect(response.parsed_body.at("input[name='top_up[paid_on]']")["min"]).to eq("2026-10-01") }
    it { expect(response.parsed_body.at(".form-hint").text).to eq("They have $109,000 left.") }
    it { expect(response.parsed_body.text.squish).to include("This money doesn't count today: it counts as you do their jobs.") }
  end

  describe "GET /advances/:advance_id/top_ups/new while the customer owes" do
    before { get new_advance_top_up_path(advance) }

    it { expect(response.parsed_body.at(".form-hint").text).to eq("Owes you $291,000.") }
  end

  describe "GET /advances/:advance_id/top_ups/new of another shop's advance" do
    before { get new_advance_top_up_path(outsider) }

    it_behaves_like "a record of another shop"
  end

  describe "POST /advances/:advance_id/top_ups" do
    let(:paid_on) { "2026-10-01" }

    before { post advance_top_ups_path(advance), params: { top_up: { paid_on:, amount: "300,000" } } }

    it { expect(response).to redirect_to(advance_path(advance)) }
    it { expect(TopUp.sole).to have_attributes(advance:, paid_on: Date.new(2026, 10, 1), amount: 300_000) }

    context "before the shop started" do
      let(:paid_on) { "2026-09-30" }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(response.parsed_body.at(".field-error").text).to eq("Date can't be before you started keeping your accounts here") }
    end
  end

  describe "POST /advances/:advance_id/top_ups to another shop's advance" do
    before { post advance_top_ups_path(outsider), params: { top_up: { paid_on: "2026-10-20", amount: "100,000" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.top_ups.count }).to eq(0) }
  end

  describe "GET /advances/:advance_id/top_ups/:id/edit" do
    before do
      create(:top_up, advance:, amount: 300_000)
      get edit_advance_top_up_path(advance, create(:top_up, advance:, amount: 100_000))
    end

    it { expect(response.parsed_body.at(".form-hint").text).to eq("Without this top-up, they have $9,000 left.") }
    it("cancels back to the advance") { expect(response.parsed_body.at("a:contains('Cancel')")["href"]).to eq(advance_path(advance)) }
  end

  describe "GET /advances/:advance_id/top_ups/:id/edit of another shop" do
    before { get edit_advance_top_up_path(outsider, outsider_top_up) }

    it_behaves_like "a record of another shop"
  end

  describe "PATCH /advances/:advance_id/top_ups/:id" do
    let(:top_up) { create(:top_up, advance:, amount: 100_000) }

    before { patch advance_top_up_path(advance, top_up), params: { top_up: { amount: "80,000" } } }

    it { expect(response).to redirect_to(advance_path(advance)) }
    it { expect(top_up.reload.amount).to eq(80_000) }
  end

  describe "PATCH /advances/:advance_id/top_ups/:id of another shop" do
    before { patch advance_top_up_path(outsider, outsider_top_up), params: { top_up: { amount: "80,000" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider_top_up.reload.amount }).to eq(100_000) }
  end

  describe "DELETE /advances/:advance_id/top_ups/:id" do
    let(:top_up) { create(:top_up, advance:) }

    before { delete advance_top_up_path(advance, top_up) }

    it { expect(response).to redirect_to(advance_path(advance)) }
    it { expect(TopUp.exists?(top_up.id)).to be(false) }
  end

  describe "DELETE /advances/:advance_id/top_ups/:id of another shop" do
    before { delete advance_top_up_path(outsider, outsider_top_up) }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { TopUp.exists?(outsider_top_up.id) }).to be(true) }
  end
end
