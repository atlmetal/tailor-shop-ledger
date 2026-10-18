require "rails_helper"

RSpec.describe "Activations", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  describe "DELETE /services/:id/activation" do
    let(:service) { create(:service, shop:) }

    before { delete service_activation_path(service) }

    it { expect(response).to redirect_to(services_path) }
    it { expect(service.reload).not_to be_active }
  end

  describe "POST /services/:id/activation" do
    let(:service) { create(:service, shop:, active: false) }

    before { post service_activation_path(service) }

    it { expect(response).to redirect_to(services_path) }
    it { expect(service.reload).to be_active }
  end

  describe "POST /services/:id/activation with the name of an active service" do
    let(:service) { create(:service, shop:, name: "Cortinas", active: false) }

    before do
      create(:service, shop:, name: "cortinas")
      post service_activation_path(service)
    end

    it { expect(flash[:alert]).to eq("You already have an active service called Cortinas: rename it to activate this one.") }
    it { expect(service.reload).not_to be_active }
  end

  describe "DELETE /services/:id/activation of another shop" do
    let(:outsider) { create(:service) }

    before { delete service_activation_path(outsider) }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.reload }).to be_active }
  end
end
