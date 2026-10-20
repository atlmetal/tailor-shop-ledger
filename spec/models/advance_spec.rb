require "rails_helper"

RSpec.describe Advance, type: :model do
  include_context "with a current shop"

  subject(:advance) { described_class.new(customer_name: "Hotel Almendros", **attributes) }

  let(:shop) { create(:shop, started_on: Date.new(2026, 10, 1)) }
  let(:attributes) { {} }

  before do
    travel_to Date.new(2026, 10, 20)
    advance.validate
  end

  it { is_expected.to be_valid }

  context "with spaces around and inside the customer's name" do
    let(:attributes) { { customer_name: "  Hotel   Almendros " } }

    it { expect(advance.customer_name).to eq("Hotel Almendros") }
  end

  context "without the customer's name" do
    let(:attributes) { { customer_name: " " } }

    it { expect(advance.errors).to be_added(:customer_name, :blank) }
  end

  context "with a name over 60 characters" do
    let(:attributes) { { customer_name: "H" * 61 } }

    it { expect(advance.errors).to be_added(:customer_name, :too_long, count: 60) }
  end

  context "for a customer who already has one, in other case" do
    let(:attributes) { { customer_name: "HOTEL ALMENDROS" } }

    before do
      create(:advance, shop:, customer_name: "Hotel Almendros")
      advance.validate
    end

    it { expect(advance.errors).to be_added(:customer_name, :taken, value: "HOTEL ALMENDROS") }
  end

  context "with the name of another shop's advance" do
    before do
      create(:advance, customer_name: "Hotel Almendros")
      advance.validate
    end

    it { is_expected.to be_valid }
  end

  context "when saved past its validations for a customer who already has one" do
    before { create(:advance, shop:, customer_name: "hotel almendros") }

    it { expect { advance.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique) }
  end

  describe "its balance" do
    subject(:recorded) { advance.reload }

    let(:advance) { create(:advance, shop:) }
    let(:service) { create(:service, shop:, price: 35_000) }

    before do
      create(:top_up, advance:, paid_on: Date.new(2026, 10, 1), amount: 300_000)
      create(:top_up, advance:, paid_on: Date.new(2026, 10, 16), amount: 100_000)
      create(:job, advance:, service:, done_on: Date.new(2026, 10, 3), quantity: 4)
    end

    it { is_expected.to have_attributes(given: 400_000, charged: 140_000, balance: 260_000) }
    it { expect(recorded.since).to eq(Date.new(2026, 10, 1)) }

    context "when its jobs charge more than the customer gave" do
      before { create(:job, advance:, service:, done_on: Date.new(2026, 10, 20), quantity: 8) }

      it("drops below 0, what the customer owes") { is_expected.to have_attributes(charged: 420_000, balance: -20_000) }
    end
  end

  context "with a job before its first top-up" do
    let(:advance) { create(:advance, shop:) }

    before do
      create(:job, advance:, service: create(:service, shop:), done_on: Date.new(2026, 10, 2))
      create(:top_up, advance:, paid_on: Date.new(2026, 10, 5))
    end

    it("starts on the job's day") { expect(advance.since).to eq(Date.new(2026, 10, 2)) }
  end

  context "without top-ups or jobs yet" do
    let(:advance) { create(:advance, shop:) }

    it { expect(advance).to have_attributes(balance: 0, since: nil) }
  end

  context "when deleted without jobs" do
    let(:advance) { create(:advance, shop:) }

    before do
      create(:top_up, advance:)
      advance.destroy
    end

    it { expect(described_class.exists?(advance.id)).to be(false) }
    it("deletes its top-ups, which never counted") { expect(TopUp.count).to eq(0) }
  end

  context "when deleted with jobs" do
    let(:advance) { create(:advance, shop:) }

    before do
      create(:top_up, advance:)
      create(:job, advance:, service: create(:service, shop:))
      advance.destroy
    end

    it("stays, since its jobs counted") { expect(described_class.exists?(advance.id)).to be(true) }
    it { expect(advance.errors).to be_added(:base, :"restrict_dependent_destroy.has_many", record: "jobs") }
    it { expect(TopUp.count).to eq(1) }
  end
end
