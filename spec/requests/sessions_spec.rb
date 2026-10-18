require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /" do
    before { get root_path }

    it { expect(response).to redirect_to(new_session_path) }
  end

  describe "GET /session/new" do
    before { get new_session_path }

    it { expect(response).to have_http_status(:ok) }
    it { expect(response.parsed_body.at("header").text).to include("Tailor Shop Ledger") }
  end

  describe "POST /session" do
    before { post session_path, params: { email_address: user.email_address, password: } }

    context "with the right password" do
      let(:password) { user.password }

      it { expect(response).to redirect_to(root_url) }
      it { expect(user.sessions.count).to eq(1) }
    end

    context "with a wrong password" do
      let(:password) { "wrong-password" }

      it { expect(response).to redirect_to(new_session_path) }
      it { expect(flash[:alert]).to eq(I18n.t("sessions.create.invalid")) }
      it { expect(user.sessions.count).to eq(0) }
    end
  end

  describe "DELETE /session" do
    include_context "with a signed-in user"

    before { delete session_path }

    it { expect(response).to redirect_to(new_session_path) }
    it { expect(user.sessions.count).to eq(0) }
  end
end
