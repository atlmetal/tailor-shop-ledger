RSpec.shared_context "with a signed-in user" do
  let(:user) { create(:user) }

  before { post session_path, params: { email_address: user.email_address, password: user.password } }
end
