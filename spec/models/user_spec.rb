require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user, attributes) }

  let(:attributes) { {} }

  before { user.validate }

  it { is_expected.to be_valid }

  context "with an email address in mixed case and padded with spaces" do
    let(:attributes) { { email_address: " Ana@Example.COM " } }

    it { expect(user.email_address).to eq("ana@example.com") }
  end

  context "without a name" do
    let(:attributes) { { name: "" } }

    it { expect(user.errors).to be_added(:name, :blank) }
  end

  context "with a malformed email address" do
    let(:attributes) { { email_address: "ana.example.com" } }

    it { expect(user.errors).to be_added(:email_address, :invalid, value: "ana.example.com") }
  end

  context "with an email address another user has in a different case" do
    let(:other_user) { create(:user, email_address: "ana@example.com") }
    let(:attributes) { { email_address: other_user.email_address.upcase } }

    it { expect(user.errors).to be_added(:email_address, :taken, value: "ana@example.com") }
  end

  context "with a password shorter than 8 characters" do
    let(:attributes) { { password: "short12" } }

    it { expect(user.errors).to be_added(:password, :too_short, count: 8) }
  end

  context "when a saved user changes to a blank password" do
    subject(:user) { described_class.find(create(:user).id) }

    before { user.validate(:password_change) }

    it { expect(user.errors).to be_added(:password, :blank) }
  end

  context "with a shop that already has its user" do
    let(:attributes) { { shop: create(:user).shop } }

    it { expect { user.save }.to raise_error(ActiveRecord::RecordNotUnique) }
  end

  describe ".generate_password" do
    it { expect(described_class.generate_password).to match(/\A[a-km-np-z2-9]{12}\z/) }
  end
end
