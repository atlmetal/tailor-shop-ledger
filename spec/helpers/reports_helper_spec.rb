require "rails_helper"

RSpec.describe ReportsHelper, type: :helper do
  let(:october) { Reports::Period.new(kind: "month", date: Date.new(2026, 10, 20)) }

  describe "#period_links" do
    subject(:links) { helper.period_links(report).join }

    let(:report) { instance_double(Reports::PeriodFacade, kind: "month") }

    before { allow(report).to receive(:period_of) { |kind| Reports::Period.new(kind:, date: Date.new(2026, 9, 30)) } }

    it("opens each kind of period by its first day") { is_expected.to have_link("Week", href: "/reports/week/2026-09-28") }
    it { is_expected.to have_link("Half", href: "/reports/semester/2026-07-01") }
    it { is_expected.to have_css("a[aria-current='page']", text: "Month") }
    it { is_expected.to have_css("a[aria-current]", count: 1) }
  end

  describe "#period_arrow" do
    it { expect(helper.period_arrow(october, "Next period") { tag.svg }).to have_css("a.period-arrow[href='/reports/month/2026-10-01'][aria-label='Next period'] svg") }
    it("dims the arrow where there's no period") { expect(helper.period_arrow(nil, "Next period") { tag.svg }).to have_css("span.period-arrow[role='link'][aria-disabled='true'][aria-label='Next period'] svg") }
  end

  describe "#period_title" do
    it { expect(helper.period_title(Reports::Period.new(kind: "day", date: Date.new(2026, 10, 20)))).to eq("Tuesday, October 20") }
    it { expect(helper.period_title(Reports::Period.new(kind: "week", date: Date.new(2026, 10, 20)))).to eq("October 19 to 25") }
    it { expect(helper.period_title(Reports::Period.new(kind: "week", date: Date.new(2026, 10, 1)))).to eq("September 28 to October 4") }
    it { expect(helper.period_title(october)).to eq("October 2026") }
    it { expect(helper.period_title(Reports::Period.new(kind: "semester", date: Date.new(2026, 3, 1)))).to eq("First half of 2026") }
    it { expect(helper.period_title(Reports::Period.new(kind: "semester", date: Date.new(2026, 10, 20)))).to eq("Second half of 2026") }
    it { expect(helper.period_title(Reports::Period.new(kind: "year", date: Date.new(2026, 10, 20)))).to eq("2026") }

    context "in es-CO" do
      around { |example| I18n.with_locale(:"es-CO") { example.run } }

      it { expect(helper.period_title(Reports::Period.new(kind: "day", date: Date.new(2026, 10, 20)))).to eq("Martes 20 de octubre") }
      it { expect(helper.period_title(Reports::Period.new(kind: "week", date: Date.new(2026, 10, 20)))).to eq("Del 19 al 25 de octubre") }
      it { expect(helper.period_title(Reports::Period.new(kind: "week", date: Date.new(2026, 10, 1)))).to eq("Del 28 de septiembre al 4 de octubre") }
      it { expect(helper.period_title(october)).to eq("Octubre de 2026") }
      it { expect(helper.period_title(Reports::Period.new(kind: "semester", date: Date.new(2026, 10, 20)))).to eq("Segundo semestre de 2026") }
    end
  end

  describe "#period_detail" do
    subject(:detail) { helper.period_detail(report) }

    let(:report) { instance_double(Reports::PeriodFacade, kind: period.kind, period:, days:, in_progress?: in_progress) }
    let(:period) { october }
    let(:days) { Date.new(2026, 10, 1)..Date.new(2026, 10, 20) }
    let(:in_progress) { true }

    context "with a month in progress" do
      it { is_expected.to eq("October 1 to 20, so far") }
      it { expect(I18n.with_locale(:"es-CO") { detail }).to eq("Del 1 al 20, hasta hoy") }
    end

    context "with a month over" do
      let(:period) { Reports::Period.new(kind: "month", date: Date.new(2026, 9, 1)) }
      let(:days) { Date.new(2026, 9, 1)..Date.new(2026, 9, 30) }
      let(:in_progress) { false }

      it { is_expected.to eq("September 1 to 30") }
    end

    context "with the month the shop started" do
      let(:period) { Reports::Period.new(kind: "month", date: Date.new(2026, 8, 3)) }
      let(:days) { Date.new(2026, 8, 3)..Date.new(2026, 8, 31) }
      let(:in_progress) { false }

      it("counts from the shop's start") { is_expected.to eq("August 3 to 31") }
    end

    context "with today" do
      let(:period) { Reports::Period.new(kind: "day", date: Date.new(2026, 10, 20)) }
      let(:days) { period.range }

      it { is_expected.to eq("Today, so far") }
      it { expect(I18n.with_locale(:"es-CO") { detail }).to eq("Hoy, hasta ahora") }
    end

    context "with a day before today" do
      let(:period) { Reports::Period.new(kind: "day", date: Date.new(2026, 10, 19)) }
      let(:days) { period.range }
      let(:in_progress) { false }

      it("adds nothing to the title") { is_expected.to be_nil }
    end

    context "with a week in progress" do
      let(:period) { Reports::Period.new(kind: "week", date: Date.new(2026, 10, 20)) }
      let(:days) { Date.new(2026, 10, 19)..Date.new(2026, 10, 20) }

      it { is_expected.to eq("So far") }
      it { expect(I18n.with_locale(:"es-CO") { detail }).to eq("Hasta hoy") }
    end

    context "with a week over" do
      let(:period) { Reports::Period.new(kind: "week", date: Date.new(2026, 10, 12)) }
      let(:days) { period.range }
      let(:in_progress) { false }

      it("adds nothing to the title") { is_expected.to be_nil }
    end

    context "with the week the shop started" do
      let(:period) { Reports::Period.new(kind: "week", date: Date.new(2026, 8, 5)) }
      let(:days) { Date.new(2026, 8, 5)..Date.new(2026, 8, 9) }
      let(:in_progress) { false }

      it("counts from the shop's start") { is_expected.to eq("August 5 to 9") }
    end

    context "with a semester in progress" do
      let(:period) { Reports::Period.new(kind: "semester", date: Date.new(2026, 10, 20)) }
      let(:days) { Date.new(2026, 7, 1)..Date.new(2026, 10, 20) }

      it { is_expected.to eq("July 1 to October 20, so far") }
      it { expect(I18n.with_locale(:"es-CO") { detail }).to eq("Del 1 de julio al 20 de octubre, hasta hoy") }
    end

    context "with a year over" do
      let(:period) { Reports::Period.new(kind: "year", date: Date.new(2025, 1, 1)) }
      let(:days) { period.range }
      let(:in_progress) { false }

      it { is_expected.to eq("January 1 to December 31") }
    end
  end

  describe "#result_summary" do
    it { expect(helper.result_summary(instance_double(Results::PeriodQuery::Result, work_days: 17, units: 112))).to eq("17 work days · 112 jobs") }
    it { expect(helper.result_summary(instance_double(Results::PeriodQuery::Result, work_days: 1, units: 1))).to eq("1 work day · 1 job") }
  end

  describe "#day_records" do
    it("shows nothing outside a day's report") { expect(helper.day_records(instance_double(Reports::PeriodFacade, day?: false))).to be_nil }
  end

  describe "#day_record_rows" do
    subject(:rows) { helper.day_record_rows(jobs, entries) }

    let(:jobs) { [ instance_double(Job, quantity: 2, service: instance_double(Service, name: "Basta de pantalón"), materials: 1_000, charged: 16_000, order: nil, to_param: "7") ] }
    let(:entries) { [ instance_double(Entry, concept: "Transporte", kind: "expense", amount: 12_000, to_param: "3") ] }

    it { is_expected.to have_link("2 × Basta de pantalón Materials $1,000 $16,000", href: "/jobs/7/edit", normalize_ws: true) }
    it { is_expected.to have_link("Transporte Expense $12,000", href: "/expenses/3/edit", normalize_ws: true) }

    context "with a day that has no records" do
      let(:jobs) { [] }
      let(:entries) { [] }

      it { is_expected.to have_text("Nothing recorded on this day.") }
    end
  end

  describe "#top_services" do
    subject(:section) { helper.top_services(report) }

    let(:report) { instance_double(Reports::PeriodFacade, day?: false, top_services: rows) }
    let(:rows) { [ Results::TopServicesQuery::Row.new(service: instance_double(Service, name: "Basta de pantalón"), units: 38, left: 285_000) ] }

    it { is_expected.to have_css("ol li", text: "Basta de pantalón 38 jobs $285,000", normalize_ws: true) }

    context "with a period without jobs" do
      let(:rows) { [] }

      it { is_expected.to be_nil }
    end

    context "with a day's report" do
      let(:report) { instance_double(Reports::PeriodFacade, day?: true) }

      it("leaves them out, since they'd repeat the day's records") { is_expected.to be_nil }
    end
  end

  describe "#top_service_left" do
    let(:row) { Results::TopServicesQuery::Row.new(service: instance_double(Service), units: 1, left:) }

    context "when the service left something" do
      let(:left) { 7_500 }

      it { expect(helper.top_service_left(row)).to have_css("span.font-mono:not(.text-loss-ink)", text: "$7,500") }
    end

    context "when its materials cost more than it charged" do
      let(:left) { -3_000 }

      it { expect(helper.top_service_left(row)).to have_css("span.text-loss-ink", text: "−$3,000") }
    end
  end

  describe "#month_label" do
    before { travel_to Date.new(2026, 10, 20) }

    it("marks the current month so it isn't compared as if it were complete") { expect(helper.month_label(Date.new(2026, 10, 1))).to eq("October, so far") }
    it { expect(helper.month_label(Date.new(2026, 9, 1))).to eq("September") }
    it { expect(I18n.with_locale(:"es-CO") { helper.month_label(Date.new(2026, 10, 1)) }).to eq("Octubre, hasta hoy") }
  end

  describe "#calculation_line" do
    it { expect(helper.calculation_line("Materials", "−$1,000")).to have_css("div > span + span.font-mono", text: "−$1,000") }
  end

  describe "#pesos_off" do
    it { expect(helper.pesos_off(151_400)).to eq("−$151,400") }
    it("keeps its sign on 0") { expect(helper.pesos_off(0)).to eq("−$0") }
  end

  describe "#pesos_on" do
    it { expect(helper.pesos_on(20_000)).to eq("+$20,000") }
  end
end
