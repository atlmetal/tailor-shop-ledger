require "rails_helper"

RSpec.describe "Today", type: :request do
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
    create(:job, service:, quantity: 2)
    create(:job, service: create(:service, shop: other_shop), quantity: 3)
  end

  describe "GET / on a work day" do
    before { get root_path }

    it { expect(response.body).to include("Modistería La Puntada") }
    it { expect(response.body).not_to include(other_shop.name) }
    it { expect(page_text).to include("So far $15,000 of the $44,074 you need today to cover the fixed costs.") }
    it { expect(page_text).to include("$29,074 to go. You charged $16,000 and the materials cost $1,000.") }
    it { expect(page_text).to include("What you recorded today 2 jobs 2 × Basta de pantalón Materials $1,000 $16,000") }
    it { expect(page_text).to include("October, so far See reports Loss −$734,259 Materials, other expenses and the fixed costs of 17 work days already taken off.") }
    it { expect(response.parsed_body.at_css("a:contains('See reports')")["href"]).to eq("/reports") }
  end

  describe "GET / on a day off" do
    before do
      travel_to Date.new(2026, 10, 25)
      get root_path
    end

    it { expect(page_text).to include("Today isn't one of your work days, so there's no goal. So far $0") }
    it { expect(response.parsed_body.at(".goal-bar")).to be_nil }
    it { expect(page_text).to include("No jobs recorded today yet.") }
  end
end
