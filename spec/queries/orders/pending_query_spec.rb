require "rails_helper"

RSpec.describe Orders::PendingQuery do
  include_context "with a current shop"

  subject(:pending) { described_class.call.map { [ it.order.customer_name, it.owed ] } }

  let(:shop) { create(:shop, started_on: Date.new(2026, 10, 1)) }
  let(:service) { create(:service, shop:, price: 25_000) }
  let(:with_a_deposit) { create(:order, shop:, customer_name: "Marta Rodríguez", received_on: Date.new(2026, 10, 15)) }
  let(:unpaid) { create(:order, shop:, customer_name: "Lucía Herrera", received_on: Date.new(2026, 10, 2)) }
  let(:paid_off) { create(:order, shop:, customer_name: "Carmen Díaz", received_on: Date.new(2026, 10, 10)) }

  before do
    travel_to Date.new(2026, 10, 20)
    create(:job, order: with_a_deposit, service:, quantity: 2)
    create(:payment, order: with_a_deposit, amount: 20_000)
    create(:job, order: unpaid, service:)
    create(:job, order: paid_off, service:)
    create(:payment, order: paid_off, amount: 25_000)
    create(:order, shop:, customer_name: "Gloria Suárez", received_on: Date.new(2026, 10, 18))
    create(:order, :with_job)
  end

  it("lists what each still owes, the oldest first, and leaves out the paid off and another shop's") do
    is_expected.to eq([ [ "Lucía Herrera", 25_000 ], [ "Marta Rodríguez", 30_000 ], [ "Gloria Suárez", 0 ] ])
  end
end
