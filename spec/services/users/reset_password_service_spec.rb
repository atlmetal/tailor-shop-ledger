require "rails_helper"

RSpec.describe Users::ResetPasswordService do
  subject(:call) { described_class.call(user:) }

  let(:user) { instance_double(User, update!: true, sessions:) }
  let(:sessions) { instance_double(ActiveRecord::Relation, destroy_all: []) }

  before do
    allow(SecureRandom).to receive(:base58).with(16).and_return("Gen3ratedPassw0rd")
    allow(User).to receive(:transaction).and_yield
  end

  it { is_expected.to eq("Gen3ratedPassw0rd") }

  it "sets the new password" do
    call

    expect(user).to have_received(:update!).with(password: "Gen3ratedPassw0rd")
  end

  it "signs the user out everywhere" do
    call

    expect(sessions).to have_received(:destroy_all)
  end
end
