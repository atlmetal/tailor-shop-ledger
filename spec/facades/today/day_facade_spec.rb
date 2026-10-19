require "rails_helper"

RSpec.describe Today::DayFacade do
  subject(:day) { described_class.new(shop:, date:) }

  let(:shop) { instance_double(Shop, work_days: [ 1, 2, 3, 4, 5, 6 ]) }
  let(:date) { Date.new(2026, 10, 20) }
  let(:result) { instance_double(Results::PeriodQuery::Result, charged:, materials: 5_600, units: 4, fixed_costs:) }
  let(:charged) { 38_000 }
  let(:fixed_costs) { 44_074 }
  let(:month) { instance_double(Results::PeriodQuery::Result) }

  before do
    allow(Results::PeriodQuery).to receive(:call).with(shop:, period: date..date).and_return(result)
    allow(Results::PeriodQuery).to receive(:call).with(shop:, period: date.all_month).and_return(month)
  end

  it { is_expected.to be_work_day }
  it { is_expected.to have_attributes(goal: 44_074, made: 32_400, left: 11_674, surplus: 0, units: 4) }
  it { expect(day.progress).to eq(Rational(32_400, 44_074)) }
  it { expect(day.month).to eq(month) }

  describe "what's owed" do
    let(:rows) { [ Orders::PendingQuery::Row.new(order: instance_double(Order), owed: 25_000), Orders::PendingQuery::Row.new(order: instance_double(Order), owed: 30_000) ] }

    before { allow(Orders::PendingQuery).to receive(:call).and_return(rows) }

    it { expect(day.pending_orders).to eq(rows) }
    it("adds up what each order owes") { expect(day.owed).to eq(55_000) }
  end

  context "when what the shop made covers the day's fixed costs" do
    let(:charged) { 60_000 }

    it { is_expected.to have_attributes(left: 0, surplus: 10_326, progress: 1) }
  end

  context "when the materials cost more than the jobs charged" do
    let(:charged) { 0 }

    it { is_expected.to have_attributes(made: -5_600, left: 49_674, progress: 0) }
  end

  context "on a day the shop doesn't work" do
    let(:date) { Date.new(2026, 10, 18) }
    let(:fixed_costs) { 0 }

    it { is_expected.not_to be_work_day }
    it { is_expected.to have_attributes(goal: 0, surplus: 32_400, progress: 0) }
  end
end
