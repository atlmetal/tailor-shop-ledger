require "rails_helper"

RSpec.describe Service, type: :model do
  include_context "with a current shop"

  subject(:service) { build(:service, shop:, **attributes) }

  let(:attributes) { {} }

  before { service.validate }

  it { is_expected.to be_valid }
  it { expect(service.leaves).to eq(7_500) }

  context "without a name" do
    let(:attributes) { { name: " " } }

    it { expect(service.errors).to be_added(:name, :blank) }
  end

  context "with spaces around and inside its name" do
    let(:attributes) { { name: "  Basta   de pantalón " } }

    it { expect(service.name).to eq("Basta de pantalón") }
  end

  context "with a negative price" do
    let(:attributes) { { price: -1 } }

    it { expect(service.errors).to be_added(:price, :greater_than_or_equal_to, value: -1, count: 0) }
  end

  context "with a price that isn't whole pesos" do
    let(:attributes) { { price: "8.000,50" } }

    it { expect(service.errors).to be_added(:price, :blank, value: nil, count: 0) }
  end

  context "without materials" do
    let(:attributes) { { material_cost: 0 } }

    it { is_expected.to be_valid }
  end

  context "with a price below its materials, as when it is always quoted" do
    let(:attributes) { { price: 0, material_cost: 500 } }

    it { is_expected.to be_valid }
    it { expect(service.leaves).to eq(-500) }
  end

  context "with the name of another active service, in other case" do
    let(:attributes) { { name: "BASTA DE PANTALÓN" } }

    before do
      create(:service, shop:, name: "Basta de pantalón")
      service.validate
    end

    it { expect(service.errors).to be_added(:name, :taken, value: "BASTA DE PANTALÓN") }
  end

  context "with the name of a deactivated service" do
    let(:attributes) { { name: "Cortinas" } }

    before do
      create(:service, shop:, name: "Cortinas", active: false)
      service.validate
    end

    it { is_expected.to be_valid }
  end

  context "when deactivated, with the name of an active service" do
    let(:attributes) { { name: "Cortinas", active: false } }

    before do
      create(:service, shop:, name: "Cortinas")
      service.validate
    end

    it { is_expected.to be_valid }
  end

  context "with the name of another shop's service" do
    let(:attributes) { { name: "Cortinas" } }

    before do
      create(:service, name: "Cortinas")
      service.validate
    end

    it { is_expected.to be_valid }
  end

  context "when saved past its validations with a negative price" do
    let(:attributes) { { price: -1 } }

    it { expect { service.save(validate: false) }.to raise_error(ActiveRecord::CheckViolation) }
  end

  context "when saved past its validations with the name of another active service" do
    let(:attributes) { { name: "basta de pantalón" } }

    before { create(:service, shop:, name: "Basta de pantalón") }

    it { expect { service.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique) }
  end
end
