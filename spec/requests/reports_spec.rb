require "rails_helper"

RSpec.describe "Reports", type: :request do
  # Created first, so a lookup that ignores the signed-in user would land on it.
  let!(:other_shop) { create(:shop, name: "Taller de Enfrente") }

  include_context "with a signed-in user"
  include_context "with a test tenant"

  let(:user) { create(:user, shop: create(:shop, name: "Modistería La Puntada", started_on: Date.new(2026, 8, 3))) }
  let(:page_text) { response.parsed_body.text.squish }

  before do
    travel_to Date.new(2026, 10, 20)
    create(:fixed_cost_amount, fixed_cost: create(:fixed_cost, shop:), starts_on: Date.new(2026, 8, 1), amount: 1_190_000)
    service = create(:service, shop:, name: "Basta de pantalón", price: 8_000, material_cost: 500)
    create(:job, service:, done_on: Date.new(2026, 10, 13), quantity: 2)
    create(:job, service:, done_on: Date.new(2026, 9, 14), quantity: 3)
    create(:entry, shop:, kind: "expense", occurred_on: Date.new(2026, 10, 14), amount: 35_000)
    create(:job, service: create(:service, shop: other_shop), done_on: Date.new(2026, 10, 13), quantity: 3)
  end

  describe "GET /reports" do
    before { get reports_path }

    it { expect(page_text).to include("October 2026 October 1 to 20, so far") }
    it { expect(page_text).to include("Loss −$769,259 17 work days · 2 jobs") }
    it { expect(page_text).to include("How it's calculated Charged for jobs $16,000 Materials −$1,000 Other income +$0 Other expenses −$35,000 Fixed costs of 17 days −$749,259 Loss −$769,259") }
    it { expect(page_text).to include("Fixed costs are spread over the days you work: in October, each day carries $44,074. See fixed costs") }
    it { expect(response.parsed_body.at("a.tab[aria-current='page']").text.squish).to eq("Reports") }
    it { expect(response.parsed_body.at("a[aria-label='Previous period']")["href"]).to eq("/reports/month/2026-09-01") }
    it { expect(response.parsed_body.at("[aria-label='Next period']")["aria-disabled"]).to eq("true") }
    it("opens each kind of period on today") { expect(response.parsed_body.css("nav.switch a").pluck("href")).to eq(%w[ /reports/day/2026-10-20 /reports/week/2026-10-19 /reports/month/2026-10-01 /reports/semester/2026-07-01 /reports/year/2026-01-01 ]) }
    it { expect(response.body).not_to include(other_shop.name) }
  end

  describe "GET /reports/month/:date of a month over" do
    before { get report_path("month", "2026-09-01") }

    it { expect(page_text).to include("September 2026 September 1 to 30") }
    it { expect(page_text).to include("Fixed costs of 26 days −$1,190,000 Loss −$1,167,500") }
    it { expect(page_text).to include("in September, each day carries $45,769.") }
    it { expect(response.parsed_body.at("a[aria-label='Next period']")["href"]).to eq("/reports/month/2026-10-01") }
    it("keeps September when switching") { expect(response.parsed_body.at("nav.switch a")["href"]).to eq("/reports/day/2026-09-30") }
  end

  describe "GET /reports/month/:date of the month the shop started" do
    before { get report_path("month", "2026-08-01") }

    it { expect(page_text).to include("August 2026 August 3 to 31") }
    it { expect(response.parsed_body.at("[aria-label='Previous period']")["aria-disabled"]).to eq("true") }
  end

  describe "GET /reports/week/:date" do
    before { get report_path("week", "2026-10-14") }

    it("shows the whole week") { expect(page_text).to include("October 12 to 18 Loss") }
    it { expect(page_text).to include("6 work days · 2 jobs") }
  end

  describe "GET /reports/semester/:date" do
    before { get report_path("semester", "2026-07-01") }

    it { expect(page_text).to include("Second half of 2026 August 3 to October 20, so far") }
  end

  describe "GET /reports/day/:date of a day off" do
    before { get report_path("day", "2026-10-18") }

    it { expect(page_text).to include("Sunday, October 18 Profit $0 0 work days · 0 jobs") }
  end

  describe "GET a period before the shop started" do
    before { get report_path("month", "2026-07-01") }

    it { expect(response).to have_http_status(:not_found) }
  end

  describe "GET a period after the current one" do
    before { get report_path("day", "2026-10-21") }

    it { expect(response).to have_http_status(:not_found) }
  end

  describe "GET a date that doesn't exist" do
    before { get "/reports/day/2026-02-30" }

    it { expect(response).to have_http_status(:not_found) }
  end

  describe "GET a kind of period that doesn't exist" do
    before { get "/reports/quarter/2026-10-01" }

    it { expect(response).to have_http_status(:not_found) }
  end
end
