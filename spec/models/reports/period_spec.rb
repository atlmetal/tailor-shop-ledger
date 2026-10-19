require "rails_helper"

RSpec.describe Reports::Period do
  subject(:period) { described_class.new(kind:, date:) }

  let(:date) { Date.new(2026, 10, 20) }

  describe "a day" do
    let(:kind) { "day" }

    it { expect(period.range).to eq(date..date) }
    it { expect(period.previous).to eq(described_class.new(kind: "day", date: Date.new(2026, 10, 19))) }
    it { expect(period.following).to eq(described_class.new(kind: "day", date: Date.new(2026, 10, 21))) }
  end

  describe "a week" do
    let(:kind) { "week" }

    it("goes from Monday to Sunday") { expect(period.range).to eq(Date.new(2026, 10, 19)..Date.new(2026, 10, 25)) }
    it { expect(period.previous.range).to eq(Date.new(2026, 10, 12)..Date.new(2026, 10, 18)) }
    it { expect(period.following.range).to eq(Date.new(2026, 10, 26)..Date.new(2026, 11, 1)) }

    context "named by its Sunday" do
      let(:date) { Date.new(2026, 10, 25) }

      it { expect(period.range).to eq(Date.new(2026, 10, 19)..Date.new(2026, 10, 25)) }
    end

    context "across two years" do
      let(:date) { Date.new(2027, 1, 1) }

      it { expect(period.range).to eq(Date.new(2026, 12, 28)..Date.new(2027, 1, 3)) }
    end
  end

  describe "a month" do
    let(:kind) { "month" }

    it { expect(period.range).to eq(Date.new(2026, 10, 1)..Date.new(2026, 10, 31)) }
    it { expect(period.previous.range).to eq(Date.new(2026, 9, 1)..Date.new(2026, 9, 30)) }
  end

  describe "a semester" do
    let(:kind) { "semester" }

    it("goes from July to December") { expect(period.range).to eq(Date.new(2026, 7, 1)..Date.new(2026, 12, 31)) }
    it { expect(period.previous.range).to eq(Date.new(2026, 1, 1)..Date.new(2026, 6, 30)) }
    it { expect(period.following.range).to eq(Date.new(2027, 1, 1)..Date.new(2027, 6, 30)) }

    context "named by June 30" do
      let(:date) { Date.new(2026, 6, 30) }

      it("goes from January to June") { expect(period.range).to eq(Date.new(2026, 1, 1)..Date.new(2026, 6, 30)) }
      it { expect(period.previous.range).to eq(Date.new(2025, 7, 1)..Date.new(2025, 12, 31)) }
    end
  end

  describe "a year" do
    let(:kind) { "year" }

    it { expect(period.range).to eq(Date.new(2026, 1, 1)..Date.new(2026, 12, 31)) }
    it { expect(period.previous.range).to eq(Date.new(2025, 1, 1)..Date.new(2025, 12, 31)) }
    it { expect(period.following.range).to eq(Date.new(2027, 1, 1)..Date.new(2027, 12, 31)) }
  end
end
