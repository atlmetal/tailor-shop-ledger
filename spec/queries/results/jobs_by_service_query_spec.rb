require "rails_helper"

RSpec.describe Results::JobsByServiceQuery do
  include_context "with a current shop"

  subject(:rows) { described_class.call(period: Date.new(2026, 10, 20)..Date.new(2026, 10, 20)) }

  let(:shirt) { create(:service, shop:, name: "Entalle de camisa", price: 16_000, material_cost: 500) }
  let(:hem) { create(:service, shop:, name: "Basta de pantalón", price: 8_000, material_cost: 500) }
  let(:names) { rows.map { it.service.name } }

  before do
    travel_to Date.new(2026, 10, 20)
    create(:job, service: shirt, quantity: 3)
    create(:job, service: hem, quantity: 2)
    create(:job, service: hem, quantity: 2, price: 9_000)
  end

  it("puts the services done the most first") { expect(names).to eq([ "Basta de pantalón", "Entalle de camisa" ]) }
  it("counts each one's units and what its jobs are worth at their price, before materials") { expect(rows.first).to have_attributes(service: hem, units: 4, worth: 2 * 8_000 + 2 * 9_000) }

  context "with jobs on other days" do
    before { create(:job, service: create(:service, shop:, name: "Cortinas"), done_on: Date.new(2026, 10, 19)) }

    it { expect(names).not_to include("Cortinas") }
  end

  context "with a tie in units" do
    before { create(:job, service: create(:service, shop:, name: "Forro de chaqueta", price: 35_000), quantity: 3) }

    it("puts the one worth more first") { expect(names).to eq([ "Basta de pantalón", "Forro de chaqueta", "Entalle de camisa" ]) }
  end

  context "with a tie in what they're worth too" do
    before { create(:job, service: create(:service, shop:, name: "Arreglo de manga", price: 16_000), quantity: 3) }

    it("puts the one added first") { expect(names).to eq([ "Basta de pantalón", "Entalle de camisa", "Arreglo de manga" ]) }
  end

  context "with an order's jobs" do
    let(:dress) { create(:service, shop:, name: "Confección de vestido", price: 180_000, material_cost: 65_000) }

    before do
      create(:job, order: create(:order, shop:, received_on: Date.new(2026, 10, 20)), service: dress)
      create(:job, order: create(:order, shop:, received_on: Date.new(2026, 10, 15)), service: dress)
    end

    it("counts those of the orders left that day, paid or not") { expect(rows.last).to have_attributes(service: dress, units: 1, worth: 180_000) }
  end

  context "with an advance's jobs" do
    let(:advance) { create(:advance, shop:).tap { create(:top_up, advance: it, amount: 200_000) } }
    let(:lining) { create(:service, shop:, name: "Forro de chaqueta", price: 35_000, material_cost: 6_000) }

    before do
      create(:job, advance:, service: lining)
      create(:job, advance:, service: lining, done_on: Date.new(2026, 10, 19))
    end

    it("counts those done that day") { expect(rows.last).to have_attributes(service: lining, units: 1, worth: 35_000) }
  end

  context "with a service deactivated since" do
    before { hem.update!(active: false) }

    it { expect(rows.first.service).to eq(hem) }
  end

  context "with another shop's jobs" do
    before { create(:job, quantity: 9) }

    it { expect(rows.size).to eq(2) }
  end
end
