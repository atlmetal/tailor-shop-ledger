require "rails_helper"

RSpec.describe "Entries", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  before { travel_to Date.new(2026, 10, 20) }

  describe "GET /expenses/new" do
    before do
      create(:entry, shop:, kind: "expense", occurred_on: Date.new(2026, 10, 14), concept: "Mantenimiento de la fileteadora", amount: 35_000)
      create(:entry, shop:, kind: "income", concept: "Venta de retazos")
      create(:entry, kind: "expense", concept: "Gasto de enfrente")
      get new_expense_path
    end

    it { expect(response.parsed_body.at("label[for='entry_concept']").text).to eq("What did you spend on?") }
    it { expect(response.parsed_body.text).to include("Fabric, thread and zippers you buy don't go here") }
    it { expect(response.parsed_body.at("section").text.squish).to eq("Latest expenses Mantenimiento de la fileteadora October 14 $35,000") }
    it { expect(response.parsed_body.css(".switch [aria-current='page']").map(&:text)).to eq([ "Expense" ]) }
  end

  describe "GET /incomes/new" do
    before { get new_income_path }

    it { expect(response.parsed_body.at("label[for='entry_concept']").text).to eq("Where did it come from?") }
    it { expect(response.parsed_body.text).to include("Money that isn't the shop's, like the rent of a room of the home, doesn't go here") }
    it { expect(response.parsed_body.at("section")).to be_nil }
  end

  describe "POST /incomes" do
    let(:entry_params) { { occurred_on: "2026-10-20", concept: "Venta de retazos", amount: "20,000" } }

    before { post incomes_path, params: { entry: entry_params } }

    it { expect(response).to redirect_to(root_path) }
    it { expect(Entry.sole).to have_attributes(kind: "income", occurred_on: Date.new(2026, 10, 20), concept: "Venta de retazos", amount: 20_000) }

    context "without an amount" do
      let(:entry_params) { super().merge(amount: "") }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(Entry.count).to eq(0) }
    end

    context "for a day before today" do
      let(:entry_params) { super().merge(occurred_on: "2026-10-13") }

      it("goes to that day's report") { expect(response).to redirect_to(report_path("day", "2026-10-13")) }
    end
  end

  describe "GET /expenses/:id/edit of a day before today" do
    before { get edit_expense_path(create(:entry, shop:, occurred_on: Date.new(2026, 10, 13))) }

    it("cancels back to that day's report") { expect(response.parsed_body.at("a:contains('Cancel')")["href"]).to eq(report_path("day", "2026-10-13")) }
  end

  describe "PATCH /expenses/:id of a day before today" do
    before { patch expense_path(create(:entry, shop:, occurred_on: Date.new(2026, 10, 13))), params: { entry: { amount: "15,000" } } }

    it { expect(response).to redirect_to(report_path("day", "2026-10-13")) }
  end

  describe "DELETE /expenses/:id of a day before today" do
    before { delete expense_path(create(:entry, shop:, occurred_on: Date.new(2026, 10, 13))) }

    it { expect(response).to redirect_to(report_path("day", "2026-10-13")) }
  end

  describe "PATCH /expenses/:id" do
    let(:entry) { create(:entry, shop:, amount: 12_000) }

    before { patch expense_path(entry), params: { entry: { amount: "15,000" } } }

    it { expect(response).to redirect_to(root_path) }
    it { expect(entry.reload.amount).to eq(15_000) }
  end

  describe "GET /incomes/:id/edit of an expense" do
    before { get edit_income_path(create(:entry, shop:, kind: "expense")) }

    it { expect(response).to have_http_status(:not_found) }
  end

  describe "DELETE /expenses/:id" do
    let(:entry) { create(:entry, shop:) }

    before { delete expense_path(entry) }

    it { expect(response).to redirect_to(root_path) }
    it { expect(Entry.exists?(entry.id)).to be(false) }
  end

  describe "GET /expenses/:id/edit of another shop" do
    before { get edit_expense_path(create(:entry)) }

    it_behaves_like "a record of another shop"
  end

  describe "PATCH /expenses/:id of another shop" do
    let(:outsider) { create(:entry, amount: 12_000) }

    before { patch expense_path(outsider), params: { entry: { amount: "1" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.reload.amount }).to eq(12_000) }
  end

  describe "DELETE /expenses/:id of another shop" do
    let(:outsider) { create(:entry) }

    before { delete expense_path(outsider) }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { Entry.exists?(outsider.id) }).to be(true) }
  end
end
