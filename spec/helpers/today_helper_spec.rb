require "rails_helper"

RSpec.describe TodayHelper, type: :helper do
  let(:day) { instance_double(Today::DayFacade, work_day?: true, progress: Rational(32_400, 44_074), charged: 38_000, materials: 5_600, made: 32_400, goal: 44_074, left:, surplus:) }
  let(:left) { 11_674 }
  let(:surplus) { 0 }

  describe "#goal_bar_width" do
    it { expect(helper.goal_bar_width(day)).to eq("73.5%") }
  end

  describe "#goal_percent" do
    it { expect(helper.goal_percent(day)).to eq(73) }
  end

  describe "#goal_note" do
    subject(:note) { helper.goal_note(day) }

    it { is_expected.to eq("<strong>$11,674 to go.</strong> You charged $38,000 and the materials cost $5,600.") }

    context "when the day's fixed costs are covered" do
      let(:left) { 0 }
      let(:surplus) { 10_326 }

      it { is_expected.to eq("<strong>Today's fixed costs are covered, and $10,326 more.</strong> You charged $38,000 and the materials cost $5,600.") }
    end

    context "when they're covered to the peso" do
      let(:left) { 0 }

      it { is_expected.to start_with("<strong>Today's fixed costs are covered.</strong>") }
    end
  end

  describe "#goal_panel" do
    it { expect(helper.goal_panel(day)).to have_css(".goal-bar[aria-label='You have 73% of today\\'s goal'] .goal-bar-fill[style='width: 73.5%']") }
    it { expect(helper.goal_panel(day)).to have_text("So far $32,400 of the $44,074 you need today to cover the fixed costs.", normalize_ws: true) }

    context "on a day off" do
      before { allow(day).to receive(:work_day?).and_return(false) }

      it { expect(helper.goal_panel(day)).to have_text("Today isn't one of your work days, so there's no goal.") }
      it { expect(helper.goal_panel(day)).to have_no_css(".goal-bar") }
    end
  end

  describe "#today_jobs" do
    it { expect(helper.today_jobs([])).to have_text("No jobs recorded today yet.") }

    it "lists each job, opening its form" do
      job = instance_double(Job, quantity: 2, service: instance_double(Service, name: "Basta de pantalón"), materials: 1_000, charged: 16_000, to_param: "7")

      expect(helper.today_jobs([ job ])).to have_link("2 × Basta de pantalón Materials $1,000 $16,000", href: "/jobs/7/edit", normalize_ws: true)
    end
  end
end
