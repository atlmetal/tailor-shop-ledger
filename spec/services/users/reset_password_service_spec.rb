require "rails_helper"

RSpec.describe Users::ResetPasswordService do
  subject(:call) { described_class.call(user:) }

  let(:user) { instance_double(User, update!: true, sessions:) }
  let(:sessions) { instance_double(ActiveRecord::Relation, destroy_all: []) }

  before do
    allow(User).to receive(:generate_password).and_return("k7m2x9pq4hta")
    allow(User).to receive(:transaction).and_yield
  end

  it { is_expected.to eq("k7m2x9pq4hta") }

  it "sets the new password" do
    call

    expect(user).to have_received(:update!).with(password: "k7m2x9pq4hta")
  end

  it "signs the user out everywhere" do
    call

    expect(sessions).to have_received(:destroy_all)
  end
end
