require "rails_helper"

RSpec.describe Shops::CreateService do
  subject(:call) { described_class.call(name: "Modistería La Puntada", started_on:, user_name: "Ana Gómez", user_email: "ana@example.com") }

  let(:started_on) { Date.new(2026, 10, 1) }
  let(:shop) { instance_double(Shop) }
  let(:user) { instance_double(User) }

  before do
    allow(User).to receive(:generate_password).and_return("k7m2x9pq4hta")
    allow(Shop).to receive(:transaction).and_yield
    allow(Shop).to receive(:create!).with(name: "Modistería La Puntada", started_on:).and_return(shop)
    allow(User).to receive(:create!).with(shop:, name: "Ana Gómez", email_address: "ana@example.com", password: "k7m2x9pq4hta").and_return(user)
  end

  it { is_expected.to have_attributes(shop:, user:, password: "k7m2x9pq4hta") }

  context "with a password of its own" do
    subject(:call) { described_class.call(name: "Modistería La Puntada", started_on:, user_name: "Ana Gómez", user_email: "ana@example.com", password: "costura-demo") }

    before { allow(User).to receive(:create!).with(shop:, name: "Ana Gómez", email_address: "ana@example.com", password: "costura-demo").and_return(user) }

    it { is_expected.to have_attributes(password: "costura-demo") }
  end

  it "creates the shop and its user in one transaction" do
    call

    expect(Shop).to have_received(:transaction)
  end
end
