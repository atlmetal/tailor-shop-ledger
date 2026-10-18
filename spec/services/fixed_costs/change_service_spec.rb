require "rails_helper"

RSpec.describe FixedCosts::ChangeService do
  subject(:call) { described_class.call(change:) }

  let(:change) { instance_double(FixedCostChange, valid?: true, fixed_cost:, starts_on: Date.new(2026, 11, 1), amount: 950_000) }
  let(:fixed_cost) { instance_double(FixedCost, amounts:) }
  let(:amounts) { instance_double(ActiveRecord::Associations::CollectionProxy) }
  let(:month_amount) { instance_double(FixedCostAmount, update!: true) }

  before { allow(amounts).to receive(:find_or_initialize_by).with(starts_on: Date.new(2026, 11, 1)).and_return(month_amount) }

  it { is_expected.to be(true) }

  it "sets the amount of the month chosen, a new one or the one that month already has" do
    call

    expect(month_amount).to have_received(:update!).with(amount: 950_000)
  end

  context "when the change isn't valid" do
    let(:change) { instance_double(FixedCostChange, valid?: false) }

    it { is_expected.to be(false) }

    it "changes no amount" do
      call

      expect(amounts).not_to have_received(:find_or_initialize_by)
    end
  end
end
