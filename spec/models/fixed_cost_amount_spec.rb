require "rails_helper"

RSpec.describe FixedCostAmount, type: :model do
  include_context "with a current shop"

  subject(:amount) { build(:fixed_cost_amount, fixed_cost:, **attributes) }

  let(:fixed_cost) { create(:fixed_cost, shop:) }
  let(:attributes) { {} }

  before { amount.validate }

  it { is_expected.to be_valid }

  context "with a negative amount" do
    let(:attributes) { { amount: -1 } }

    it { expect(amount.errors).to be_added(:amount, :greater_than_or_equal_to, value: -1, count: 0) }
  end

  context "when saved past its validations from the middle of a month" do
    let(:attributes) { { starts_on: Date.new(2026, 10, 15) } }

    it { expect { amount.save(validate: false) }.to raise_error(ActiveRecord::CheckViolation) }
  end

  context "when saved with a month its fixed cost already has" do
    before { create(:fixed_cost_amount, fixed_cost:) }

    it { expect { amount.save }.to raise_error(ActiveRecord::RecordNotUnique) }
  end
end
