require "rails_helper"

RSpec.describe Reports::PeriodFacade do
  subject(:report) { described_class.new(shop:, period:) }

  let(:shop) { instance_double(Shop, started_on: Date.new(2026, 8, 3)) }
  let(:period) { Reports::Period.new(kind: "month", date: Date.new(2026, 9, 1)) }
  let(:result) { instance_double(Results::PeriodQuery::Result, days: Date.new(2026, 9, 1)..Date.new(2026, 9, 30)) }

  before do
    travel_to Date.new(2026, 10, 20)
    allow(Results::PeriodQuery).to receive(:call).with(shop:, period: period.range).and_return(result)
  end

  it { expect(report.result).to eq(result) }
  it { is_expected.not_to be_in_progress }
  it { expect(report.previous).to eq(Reports::Period.new(kind: "month", date: Date.new(2026, 8, 31))) }
  it { expect(report.following).to eq(Reports::Period.new(kind: "month", date: Date.new(2026, 10, 1))) }
  it("switches to the period that holds the last day counted") { expect(report.period_of("day")).to eq(Reports::Period.new(kind: "day", date: Date.new(2026, 9, 30))) }

  context "with the shop's first period" do
    let(:period) { Reports::Period.new(kind: "month", date: Date.new(2026, 8, 3)) }

    it { expect(report.previous).to be_nil }
  end

  context "with the current period" do
    let(:period) { Reports::Period.new(kind: "month", date: Date.new(2026, 10, 20)) }
    let(:result) { instance_double(Results::PeriodQuery::Result, days: Date.new(2026, 10, 1)..Date.new(2026, 10, 20)) }

    it { is_expected.to be_in_progress }
    it { expect(report.following).to be_nil }
    it("switches to the current period of each kind") { expect(report.period_of("week")).to eq(Reports::Period.new(kind: "week", date: Date.new(2026, 10, 20))) }
  end

  describe "#fixed_costs_month" do
    let(:month) { instance_double(FixedCosts::MonthQuery::Result) }

    before { allow(FixedCosts::MonthQuery).to receive(:call).with(shop:, month: Date.new(2026, 9, 30)).and_return(month) }

    it("is the month of the last day counted") { expect(report.fixed_costs_month).to eq(month) }
  end
end
