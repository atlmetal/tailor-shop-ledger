require "rails_helper"

RSpec.describe "Shell", type: :system do
  include_context "with a user signed in from the browser"

  let(:user) { create(:user, shop: create(:shop, name: "Modistería La Puntada")) }
  let(:tab_bar) { find("nav", text: "Today") }

  it { expect(page).to have_css("header", text: "Modistería La Puntada") }
  it { expect(page).to have_css("a[aria-current='page']", text: "Today") }

  it "keeps the tab bar at the bottom of a phone's screen" do
    expect(tab_bar.rect.y + tab_bar.rect.height).to eq(page.evaluate_script("window.innerHeight"))
  end

  it "moves the tab bar above the page on a wide screen", :desktop do
    expect(tab_bar.rect.y).to be < find("main").rect.y
  end

  it "signs out from the account page" do
    click_on "Your account"
    click_on "Sign out"

    expect(page).to have_button("Sign in")
  end
end
