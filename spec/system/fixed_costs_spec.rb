require "rails_helper"

RSpec.describe "Fixed costs", type: :system do
  include_context "with a user signed in from the browser"

  let(:row) { find("details", text: "Arriendo del local") }

  before do
    travel_to Date.new(2026, 10, 20)
    create(:fixed_cost_amount, fixed_cost: create(:fixed_cost, shop: user.shop, name: "Arriendo del local"), starts_on: Date.new(2026, 9, 1), amount: 900_000)
    visit fixed_costs_path
    row.find("summary").click
  end

  it "says which months keep the old amount for the month chosen" do
    expect(row).to have_text("October and the months before keep $900,000.")

    row.select "December 2026", from: "From"

    expect(row).to have_text("October, November and the months before keep $900,000.")
    expect(row).to have_no_text("October and the months before keep")
  end

  it "changes the amount from the month chosen and notes it in the row" do
    row.fill_in "New monthly amount", with: "950000"
    row.click_on "Save change"

    expect(page).to have_css("summary", text: "Arriendo del local From November: $950,000 $900,000", normalize_ws: true)
  end
end
