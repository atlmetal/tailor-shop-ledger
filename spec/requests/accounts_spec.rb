require "rails_helper"

RSpec.describe "Account", type: :request do
  include_context "with a signed-in user"

  describe "GET /account" do
    before { get account_path }

    it { expect(response).to have_http_status(:ok) }
  end

  describe "PATCH /account" do
    let(:other_session) { create(:session, user:) }
    let(:password_params) { { password_challenge: "password123", password: "new-password", password_confirmation: "new-password" } }

    before do
      other_session
      patch account_path, params: { user: password_params }
    end

    context "with the current password" do
      it { expect(response).to redirect_to(account_path) }
      it { expect(user.reload.authenticate("new-password")).to eq(user) }
      it { expect(Session.exists?(other_session.id)).to be(false) }
      it { expect(user.sessions.count).to eq(1) }
    end

    context "with a wrong current password" do
      let(:password_params) { super().merge(password_challenge: "wrong-password") }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(response.parsed_body.at("a[aria-current='page']")["href"]).to eq(account_path) }
      it { expect(user.reload.authenticate("password123")).to eq(user) }
      it { expect(Session.exists?(other_session.id)).to be(true) }
    end

    context "without the current password" do
      let(:password_params) { super().except(:password_challenge) }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(user.reload.authenticate("password123")).to eq(user) }
    end

    context "with a blank new password" do
      let(:password_params) { super().merge(password: "", password_confirmation: "") }

      it { expect(response).to have_http_status(:unprocessable_content) }
    end
  end
end
