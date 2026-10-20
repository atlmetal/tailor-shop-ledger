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

  describe "GET / with orders" do
    let(:zipper) { create(:service, shop:, name: "Cambio de cremallera", price: 15_000, material_cost: 2_800) }
    let(:left_today) { create(:order, shop:, customer_name: "Marta Rodríguez", received_on: Date.new(2026, 10, 20)) }
    let(:left_before) { create(:order, shop:, customer_name: "Lucía Herrera", received_on: Date.new(2026, 10, 2)) }

    before do
      create(:job, order: left_today, service: zipper, quantity: 2)
      create(:payment, order: left_today, amount: 10_000)
      create(:job, order: left_before, service: zipper)
      get root_path
    end

    it("counts today's payment, never an order's price, and the materials of the order left today") do
      expect(page_text).to include("So far $19,400 of the $44,074 you need today")
    end

    it { expect(page_text).to include("$24,674 to go. You charged $26,000 and the materials cost $6,600.") }
    it { expect(page_text).to include("What you recorded today 4 jobs 2 × Basta de pantalón Materials $1,000 $16,000 Order for Marta Rodríguez 2 jobs · Materials $5,600") }
    it { expect(page_text).to include("Payment from Marta Rodríguez Order of October 20 $10,000") }
    it("lists what's owed, the oldest first") { expect(page_text).to include("Owed to you $35,000 Lucía Herrera Left on October 2 $15,000 Marta Rodríguez Left on October 20 $20,000") }
    it { expect(response.parsed_body.css("[aria-labelledby='owed'] a").pluck("href")).to eq([ order_path(left_before), order_path(left_today) ]) }
  end

  describe "GET / with nothing owed" do
    before { get root_path }

    it { expect(page_text).not_to include("Owed to you") }
  end

  describe "GET / with advances" do
    let(:zipper) { create(:service, shop:, name: "Cambio de cremallera", price: 15_000, material_cost: 2_800) }
    let(:hotel) { create(:advance, shop:, customer_name: "Hotel Almendros") }
    let(:lucia) { create(:advance, shop:, customer_name: "Lucía Restrepo") }

    before do
      create(:top_up, advance: hotel, paid_on: Date.new(2026, 10, 1), amount: 124_000)
      create(:job, advance: hotel, service: zipper)
      create(:top_up, advance: lucia, paid_on: Date.new(2026, 10, 5), amount: 26_000)
      create(:job, advance: lucia, service: zipper, done_on: Date.new(2026, 10, 19), quantity: 2)
      get root_path
    end

    it("counts today's job in an advance as a job on its own, and never the top-ups") do
      expect(page_text).to include("$16,874 to go. You charged $31,000 and the materials cost $3,800.")
    end

    it { expect(page_text).to include("What you recorded today 3 jobs 2 × Basta de pantalón Materials $1,000 $16,000 1 × Cambio de cremallera Advance from Hotel Almendros Materials $2,800 $15,000") }
    it("opens the advance's job under it") { expect(response.parsed_body.at("a:contains('1 × Cambio de cremallera')")["href"]).to eq(edit_advance_job_path(hotel, hotel.jobs.sole)) }
    it { expect(page_text).to include("Advances New advance Hotel Almendros Still has $109,000 Lucía Restrepo Owes you $4,000") }
    it { expect(response.parsed_body.css("[aria-labelledby='advances'] a").pluck("href")).to eq([ new_advance_path, advance_path(hotel), advance_path(lucia) ]) }
    it("leaves what an advance owes out of what orders owe") { expect(page_text).not_to include("Owed to you") }
  end

  describe "GET / without advances" do
    before { get root_path }

    it { expect(page_text).to include("Advances For customers who pay you up front and bring you work as they go. New advance") }
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
