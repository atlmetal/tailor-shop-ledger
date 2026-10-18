require "rails_helper"

RSpec.describe FixedCosts::CreateService do
  subject(:call) { described_class.call(form:) }

  let(:form) { instance_double(NewFixedCost, valid?: true, name: "Arriendo del local", averaged: false, starts_on: Date.new(2026, 8, 1), amount: 900_000) }
  let(:fixed_cost) { instance_double(FixedCost, amounts:) }
  let(:amounts) { instance_double(ActiveRecord::Associations::CollectionProxy, create!: nil) }

  before do
    allow(FixedCost).to receive(:transaction).and_yield
    allow(FixedCost).to receive(:create!).with(name: "Arriendo del local", averaged: false).and_return(fixed_cost)
  end

  it { is_expected.to eq(fixed_cost) }

  it "gives the fixed cost its first amount, from the month chosen" do
    call

    expect(amounts).to have_received(:create!).with(starts_on: Date.new(2026, 8, 1), amount: 900_000)
  end

  it "adds both in one transaction" do
    call

    expect(FixedCost).to have_received(:transaction)
  end

  context "when the form isn't valid" do
    let(:form) { instance_double(NewFixedCost, valid?: false) }

    it { is_expected.to be(false) }

    it "adds nothing" do
      call

      expect(FixedCost).not_to have_received(:create!)
    end
  end
end
