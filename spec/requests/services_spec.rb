require "rails_helper"

RSpec.describe "Services", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  describe "GET /services" do
    before do
      create(:service, shop:, name: "Basta de pantalón", price: 8_000, material_cost: 500)
      create(:service, shop:, name: "Ajuste de cintura")
      create(:service, shop:, name: "Cortinas", active: false)
      create(:service, name: "Bordado de enfrente")
      get services_path
    end

    it { expect(response.parsed_body.at("a[href='#{edit_service_path(Service.find_by!(name: "Basta de pantalón"))}']").text.squish).to eq("Basta de pantalón $8,000 Materials $500 Leaves you $7,500") }
    it { expect(response.parsed_body.at("details").text.squish).to eq("Deactivated (1) Cortinas $8,000 Activate") }
    it { expect(response.body).not_to include("Bordado de enfrente") }
    it { expect(response.parsed_body.css(".panel > a .font-bold:first-child").map(&:text)).to eq([ "Basta de pantalón", "Ajuste de cintura" ]) }
  end

  describe "POST /services" do
    let(:service_params) { { name: "Basta de pantalón", price: "8,000", material_cost: "500" } }

    before { post services_path, params: { service: service_params } }

    it { expect(response).to redirect_to(services_path) }
    it { expect(Service.sole).to have_attributes(name: "Basta de pantalón", price: 8_000, material_cost: 500, active: true) }

    context "without a name" do
      let(:service_params) { super().merge(name: "") }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(Service.count).to eq(0) }
    end
  end

  describe "GET /services/:id/edit" do
    before { get edit_service_path(create(:service, shop:)) }

    it { expect(response).to have_http_status(:ok) }
  end

  describe "GET /services/:id/edit of another shop" do
    before { get edit_service_path(create(:service)) }

    it_behaves_like "a record of another shop"
  end

  describe "PATCH /services/:id" do
    let(:service) { create(:service, shop:, price: 8_000) }

    before { patch service_path(service), params: { service: { price: "9,000" } } }

    it { expect(response).to redirect_to(services_path) }
    it { expect(service.reload.price).to eq(9_000) }
  end

  describe "PATCH /services/:id of another shop" do
    let(:outsider) { create(:service, price: 8_000) }

    before { patch service_path(outsider), params: { service: { price: "1" } } }

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.reload.price }).to eq(8_000) }
  end
end
