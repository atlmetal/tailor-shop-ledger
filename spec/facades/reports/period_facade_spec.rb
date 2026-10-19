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

  describe "#top_services" do
    let(:rows) { [ instance_double(Results::TopServicesQuery::Row) ] }

    before { allow(Results::TopServicesQuery).to receive(:call).with(period: result.days).and_return(rows) }

    it("ranks the services of the days counted") { expect(report.top_services).to eq(rows) }
  end

  describe "#months" do
    let(:month_result) { instance_double(Results::PeriodQuery::Result) }

    before { allow(Results::PeriodQuery).to receive(:call).and_return(month_result) }

    it("goes back from the current month, without the ones before the shop started") { expect(report.months.keys).to eq([ Date.new(2026, 10, 1), Date.new(2026, 9, 1), Date.new(2026, 8, 1) ]) }
    it { expect(report.months.values).to all(eq(month_result)) }

    it "counts each month whole" do
      report.months
      expect(Results::PeriodQuery).to have_received(:call).with(shop:, period: Date.new(2026, 9, 1)..Date.new(2026, 9, 30))
    end

    context "with a shop that started long before" do
      let(:shop) { instance_double(Shop, started_on: Date.new(2025, 11, 4)) }

      it("keeps the last six") { expect(report.months.keys).to eq([ Date.new(2026, 10, 1), Date.new(2026, 9, 1), Date.new(2026, 8, 1), Date.new(2026, 7, 1), Date.new(2026, 6, 1), Date.new(2026, 5, 1) ]) }
    end
  end
end
