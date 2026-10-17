require "rails_helper"

RSpec.describe "Smoke", type: :system do
  it "serves the health check to a headless browser" do
    visit rails_health_check_path

    expect(page).to have_css("body[style*='green']")
  end
end
