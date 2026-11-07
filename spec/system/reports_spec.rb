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

  it "shows a day's jobs by service, paid or not" do
    shirt = create(:service, shop: user.shop, name: "Shirt taken in", price: 16_000)
    create(:job, order: create(:order, shop: user.shop), service: shirt, quantity: 2)
    create(:job, service: shirt)
    create(:job, service: create(:service, shop: user.shop, name: "Trouser hem", price: 8_000))

    click_on "Reports"
    click_on "Day"

    expect(page).to have_text("Tuesday, October 20")
    expect(page).to have_css("tbody tr:first-child", text: "3 Shirt taken in $48,000", normalize_ws: true)
    expect(page).to have_css("tfoot", text: "4 Total $56,000", normalize_ws: true)
    expect(page).to have_text("What you charged on this day is above, under Charged for jobs: $24,000.")
  end
end
