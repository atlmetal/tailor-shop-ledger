require "rails_helper"

RSpec.describe "Jobs", type: :system do
  include_context "with a user signed in from the browser"

  let(:jobs) { ActsAsTenant.with_tenant(user.shop) { Job.order(:id).map { [ it.service.name, it.quantity, it.price, it.material_cost ] } } }

  before do
    create(:service, shop: user.shop, name: "Basta de pantalón", price: 8_000, material_cost: 500)
    create(:service, shop: user.shop, name: "Cambio de cremallera", price: 15_000, material_cost: 2_800)
    visit new_job_path
  end

  it "fills in the service's price and materials, and sums up the job while it's typed" do
    choose "Cambio de cremallera"
    click_on "One more"

    expect(page).to have_field("Price of each", with: "15,000")
    expect(page).to have_text("You charge $30,000 Materials −$5,600 Leaves you $24,400", normalize_ws: true)
  end

  it "records two jobs in a row, the second at another price" do
    choose "Basta de pantalón"
    click_on "One more"
    click_on "Save and record another"

    expect(page).to have_text("Saved: 2 × Basta de pantalón, $16,000. Go on with the next one.")
    expect(page).to have_checked_field("Basta de pantalón")
    expect(page).to have_field("Quantity", with: "1")

    fill_in "Price of each", with: "10000"
    click_on "Save"

    expect(page).to have_current_path(root_path)
    expect(jobs).to eq([ [ "Basta de pantalón", 2, 8_000, 500 ], [ "Basta de pantalón", 1, 10_000, 500 ] ])
  end
end
