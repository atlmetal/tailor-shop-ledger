require "rails_helper"

RSpec.describe "Advances", type: :system do
  include_context "with a user signed in from the browser"

  before do
    travel_to Date.new(2026, 10, 20)
    create(:fixed_cost_amount, fixed_cost: create(:fixed_cost, shop: user.shop), starts_on: Date.new(2026, 1, 1), amount: 1_190_000)
    create(:service, shop: user.shop, name: "Basta de pantalón", price: 8_000, material_cost: 500)
    create(:service, shop: user.shop, name: "Forro de chaqueta", price: 35_000, material_cost: 6_000)
  end

  it "takes an advance with a top-up and two jobs, the second past the balance, then a top-up, which Today never counts" do
    visit root_path
    within("[aria-labelledby='advances']") { click_on "New advance" }
    fill_in "Whose advance is it?", with: "Hotel Almendros"
    click_on "Continue"

    fill_in "Amount", with: "100000"
    click_on "Save"
    expect(page).to have_text("Still has $100,000 Gave you $100,000, and you've done $0 in jobs for them.", normalize_ws: true)

    visit root_path
    expect(page).to have_text("So far $0 of the $44,074 you need today", normalize_ws: true)
    expect(page).to have_text("Hotel Almendros Still has $100,000", normalize_ws: true)

    within("[aria-labelledby='advances']") { click_on "Hotel Almendros" }
    click_on "Add a job"
    choose "Basta de pantalón"
    click_on "One more"
    expect(page).to have_text("This job −$16,000 Would still have $84,000", normalize_ws: true)
    click_on "Save and add another"
    expect(page).to have_text("Saved: 2 × Basta de pantalón, $16,000. Go on with the next one.")

    choose "Forro de chaqueta"
    click_on "One more"
    click_on "One more"
    click_on "One more"
    expect(page).to have_css("[role='status']", text: "The customer would owe $56,000.")
    click_on "Save"
    expect(page).to have_text("Owes you $56,000 Gave you $100,000, and you've done $156,000 in jobs for them.", normalize_ws: true)

    visit root_path
    expect(page).to have_text("So far $131,000 of the $44,074 you need today", normalize_ws: true)
    expect(page).to have_text("Hotel Almendros Owes you $56,000", normalize_ws: true)

    within("[aria-labelledby='advances']") { click_on "Hotel Almendros" }
    click_on "Record a top-up"
    expect(page).to have_text("Owes you $56,000.")
    fill_in "Amount", with: "200000"
    click_on "Save"
    expect(page).to have_text("Still has $144,000", normalize_ws: true)

    visit root_path
    expect(page).to have_text("So far $131,000 of the $44,074 you need today", normalize_ws: true)
    expect(page).to have_text("Hotel Almendros Still has $144,000", normalize_ws: true)
  end
end
