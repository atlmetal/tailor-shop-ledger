require "rails_helper"

RSpec.describe "Reports", type: :system do
  include_context "with a user signed in from the browser"

  before do
    travel_to Date.new(2026, 10, 20)
    create(:fixed_cost_amount, fixed_cost: create(:fixed_cost, shop: user.shop), starts_on: Date.new(2026, 1, 1), amount: 1_190_000)
    create(:job, service: create(:service, shop: user.shop, price: 8_000, material_cost: 500), done_on: Date.new(2026, 9, 14), quantity: 3)
  end

  it "goes from the current month to the previous one" do
    click_on "Reports"
    expect(page).to have_text("October 2026")

    click_on "Previous period"

    expect(page).to have_text("September 2026")
    expect(page).to have_text("Charged for jobs $24,000", normalize_ws: true)
  end
end
