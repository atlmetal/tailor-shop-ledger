require "rails_helper"

RSpec.describe Advances::BalancesQuery do
  include_context "with a current shop"

  subject(:balances) { described_class.call.map { [ it.advance.customer_name, it.balance ] } }

  let(:shop) { create(:shop, started_on: Date.new(2026, 10, 1)) }
  let(:service) { create(:service, shop:, price: 35_000) }
  let(:hotel) { create(:advance, shop:, customer_name: "Hotel Almendros") }
  let(:lucia) { create(:advance, shop:, customer_name: "lucía Restrepo") }

  before do
    travel_to Date.new(2026, 10, 20)
    create(:top_up, advance: hotel, amount: 300_000)
    create(:top_up, advance: hotel, amount: 100_000)
    create(:job, advance: hotel, service:, quantity: 4)
    create(:top_up, advance: lucia, amount: 120_000)
    create(:job, advance: lucia, service:, quantity: 2)
    create(:job, advance: lucia, service:, quantity: 2)
    create(:advance, shop:, customer_name: "Carmen Díaz")
    create(:top_up, advance: create(:advance, customer_name: "Hotel del Parque"))
  end

  it("lists each advance by name, ignoring case, with what's left or below 0 what the customer owes, and leaves out another shop's") do
    is_expected.to eq([ [ "Carmen Díaz", 0 ], [ "Hotel Almendros", 260_000 ], [ "lucía Restrepo", -20_000 ] ])
  end
end
