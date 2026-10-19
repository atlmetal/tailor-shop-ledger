require "rails_helper"

RSpec.describe Results::TopServicesQuery do
  include_context "with a current shop"

  subject(:rows) { described_class.call(period: Date.new(2026, 10, 1)..Date.new(2026, 10, 20)) }

  let(:hem) { create(:service, shop:, name: "Basta de pantalón", price: 8_000, material_cost: 500) }
  let(:zipper) { create(:service, shop:, name: "Cambio de cremallera", price: 15_000, material_cost: 2_800) }
  let(:names) { rows.map { it.service.name } }

  before do
    travel_to Date.new(2026, 10, 20)
    create(:job, service: zipper, done_on: Date.new(2026, 10, 7), quantity: 2)
    create(:job, service: hem, done_on: Date.new(2026, 10, 5), quantity: 3)
    create(:job, service: hem, done_on: Date.new(2026, 10, 6), material_cost: 0)
  end

  it("ranks the services by what they left") { expect(names).to eq([ "Basta de pantalón", "Cambio de cremallera" ]) }
  it("counts each one's units and what its jobs left") { expect(rows.first).to have_attributes(service: hem, units: 4, left: 3 * 7_500 + 8_000) }

  context "with jobs outside the period" do
    before { create(:job, service: create(:service, shop:, name: "Cortinas", price: 45_000), done_on: Date.new(2026, 9, 30)) }

    it { expect(names).not_to include("Cortinas") }
  end

  context "with a tie in what they left" do
    before do
      create(:job, service: create(:service, shop:, name: "Ruedo", price: 15_250, material_cost: 0), quantity: 2)
      create(:job, service: create(:service, shop:, name: "Forro", price: 30_500, material_cost: 0))
    end

    it("puts the one with more units first") { expect(names.first(3)).to eq([ "Basta de pantalón", "Ruedo", "Forro" ]) }
  end

  context "with a tie in units too" do
    before { create(:job, service: create(:service, shop:, name: "Ruedo", price: 12_200, material_cost: 0), quantity: 2) }

    it("puts the one added first") { expect(names).to eq([ "Basta de pantalón", "Cambio de cremallera", "Ruedo" ]) }
  end

  context "with more than five services" do
    before do
      create(:job, service: create(:service, shop:, name: "Ruedo", price: 20_000, material_cost: 0))
      create(:job, service: create(:service, shop:, name: "Botones", price: 7_000, material_cost: 0))
      create(:job, service: create(:service, shop:, name: "Cintura", price: 14_000, material_cost: 0))
      create(:job, service: create(:service, shop:, name: "Bolsillo", price: 5_000, material_cost: 0))
    end

    it("keeps the top five") { expect(names).to eq([ "Basta de pantalón", "Cambio de cremallera", "Ruedo", "Cintura", "Botones" ]) }
  end

  context "with an order's jobs" do
    let(:dress) { create(:service, shop:, name: "Confección de vestido", price: 180_000, material_cost: 65_000) }

    before do
      create(:job, order: create(:order, shop:, received_on: Date.new(2026, 10, 9)), service: dress)
      create(:job, order: create(:order, shop:, received_on: Date.new(2026, 9, 29)), service: dress)
    end

    it("counts those of the orders left in the period, with what they'll leave") { expect(rows.first).to have_attributes(service: dress, units: 1, left: 115_000) }
  end

  context "with another shop's jobs" do
    before { create(:job, done_on: Date.new(2026, 10, 7), quantity: 9) }

    it { expect(rows.size).to eq(2) }
  end
end
