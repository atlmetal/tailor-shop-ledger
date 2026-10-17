require "rails_helper"

RSpec.describe "Today", type: :request do
  # Created first, so a lookup that ignores the signed-in user would land on it.
  let!(:other_shop) { create(:shop, name: "Taller de Enfrente") }

  include_context "with a signed-in user"

  let(:user) { create(:user, shop: create(:shop, name: "Modistería La Puntada")) }

  describe "GET /" do
    before { get root_path }

    it { expect(response.body).to include("Modistería La Puntada") }
    it { expect(response.body).not_to include(other_shop.name) }
  end
end
