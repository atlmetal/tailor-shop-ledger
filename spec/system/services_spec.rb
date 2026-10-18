require "rails_helper"

RSpec.describe "Services", type: :system do
  include_context "with a user signed in from the browser"

  let(:price) { find_field("Price") }

  before { visit new_service_path }

  it "groups a price's digits as they are typed" do
    fill_in "Price", with: "120000"

    expect(page).to have_field("Price", with: "120,000")
  end

  it "takes digits only" do
    fill_in "Price", with: "12a3-4.5"

    expect(page).to have_field("Price", with: "12,345")
  end

  it "keeps the caret after a digit typed in the middle, though the grouping moves" do
    fill_in "Price", with: "100000"
    price.send_keys(:home, :right, "5", "5")

    expect(page).to have_field("Price", with: "15,500,000")
  end

  it "keeps a pasted amount's pesos and drops its cents" do
    page.execute_script(<<~JS, price)
      arguments[0].value = "$ 120,450.00"
      arguments[0].dispatchEvent(new InputEvent("input", { inputType: "insertFromPaste", bubbles: true }))
    JS

    expect(page).to have_field("Price", with: "120,450")
  end

  it "saves a new service with its amounts in pesos" do
    fill_in "Name", with: "Basta de pantalón"
    fill_in "Price", with: "8000"
    fill_in "Materials", with: "500"
    click_on "Save"

    expect(page).to have_link("Basta de pantalón $8,000 Materials $500 Leaves you $7,500")
  end
end
