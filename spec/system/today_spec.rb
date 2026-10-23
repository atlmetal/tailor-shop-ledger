require "rails_helper"

RSpec.describe "Today", type: :system do
  include_context "with a user signed in from the browser"

  let(:goal_bar) { find("[role='img']") }

  before do
    travel_to Date.new(2026, 10, 20)
    create(:fixed_cost_amount, fixed_cost: create(:fixed_cost, shop: user.shop), starts_on: Date.new(2026, 1, 1), amount: 1_190_000)
    create(:service, shop: user.shop, name: "Basta de pantalón", price: 8_000, material_cost: 500)
    visit root_path
  end

  it "fills the day's goal with a job just recorded" do
    expect(page).to have_text("So far $0 of the $44,074 you need today", normalize_ws: true)

    click_on "Record an order"
    click_on "Job"
    choose "Basta de pantalón"
    click_on "One more"
    click_on "Save"

    expect(page).to have_text("So far $15,000 of the $44,074 you need today", normalize_ws: true)
    expect(page).to have_text("$29,074 to go.")
    expect(goal_bar["aria-label"]).to eq("You have 34% of today's goal")
  end
end
