# System specs: signs in through the form, and waits for Today so the next visit already has the session.
RSpec.shared_context "with a user signed in from the browser" do
  let(:user) { create(:user) }

  before do
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: user.password
    click_on "Sign in"
    expect(page).to have_current_path(root_path)
  end
end
