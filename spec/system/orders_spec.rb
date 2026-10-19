require "rails_helper"

RSpec.describe "Orders", type: :system do
  include_context "with a user signed in from the browser"

  before do
    travel_to Date.new(2026, 10, 20)
    create(:fixed_cost_amount, fixed_cost: create(:fixed_cost, shop: user.shop), starts_on: Date.new(2026, 1, 1), amount: 1_190_000)
    create(:service, shop: user.shop, name: "Basta de pantalón", price: 8_000, material_cost: 500)
    create(:service, shop: user.shop, name: "Cambio de cremallera", price: 15_000, material_cost: 2_800)
  end

  it "takes an order with two jobs and a deposit, then its last payment, which Today counts the day each comes in" do
    visit new_order_path
    fill_in "Whose order is it?", with: "Marta Rodríguez"
    click_on "Continue"

    choose "Basta de pantalón"
    click_on "One more"
    click_on "Save and add another"
    expect(page).to have_text("Saved: 2 × Basta de pantalón, $16,000. Go on with the next one.")

    choose "Cambio de cremallera"
    click_on "Save"
    expect(page).to have_text("Owes you $31,000 Has paid you $0 of $31,000.", normalize_ws: true)

    click_on "Record a payment"
    fill_in "Amount", with: "10000"
    click_on "Save"
    expect(page).to have_text("Owes you $21,000 Has paid you $10,000 of $31,000.", normalize_ws: true)

    visit root_path
    expect(page).to have_text("So far $6,200 of the $44,074 you need today", normalize_ws: true)
    expect(page).to have_text("Owed to you $21,000", normalize_ws: true)

    within("[aria-labelledby='owed']") { click_on "Marta Rodríguez" }
    click_on "Record a payment"
    expect(page).to have_field("Amount", with: "21,000")
    click_on "Save"
    expect(page).to have_text("Paid off $31,000 Paid you the whole order.", normalize_ws: true)

    visit root_path
    expect(page).to have_text("So far $27,200 of the $44,074 you need today", normalize_ws: true)
    expect(page).to have_no_text("Owed to you")
  end
end
