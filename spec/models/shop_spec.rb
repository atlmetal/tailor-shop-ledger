require "rails_helper"

RSpec.describe Shop, type: :model do
  subject(:shop) { build(:shop, attributes) }

  let(:attributes) { {} }

  before { shop.validate }

  it { is_expected.to be_valid }
  it { expect(described_class.new.work_days).to eq([ 1, 2, 3, 4, 5, 6 ]) }

  context "without a name" do
    let(:attributes) { { name: "" } }

    it { expect(shop.errors).to be_added(:name, :blank) }
  end

  context "without a start date" do
    let(:attributes) { { started_on: nil } }

    it { expect(shop.errors).to be_added(:started_on, :blank) }
  end

  context "without work days" do
    let(:attributes) { { work_days: [] } }

    it { expect { shop.save }.to raise_error(ActiveRecord::CheckViolation) }
  end

  context "with a weekday outside 0 to 6" do
    let(:attributes) { { work_days: [ 1, 7 ] } }

    it { expect { shop.save }.to raise_error(ActiveRecord::CheckViolation) }
  end
end
