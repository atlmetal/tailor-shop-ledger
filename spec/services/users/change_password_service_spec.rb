require "rails_helper"

RSpec.describe Users::ChangePasswordService do
  subject(:call) { described_class.call(session:, attributes:) }

  let(:session) { instance_double(Session, user:) }
  let(:user) { instance_double(User, assign_attributes: nil, save: saved, sessions:) }
  let(:sessions) { instance_double(ActiveRecord::Relation, excluding: other_sessions) }
  let(:other_sessions) { instance_double(ActiveRecord::Relation, destroy_all: []) }
  let(:attributes) { { password_challenge: "password123", password: "new-password", password_confirmation: "new-password" } }
  let(:saved) { true }

  it { is_expected.to eq(user) }

  it "assigns the new password" do
    call

    expect(user).to have_received(:assign_attributes).with(attributes)
  end

  it "saves in the password change context" do
    call

    expect(user).to have_received(:save).with(context: :password_change)
  end

  it "signs out every other session of the user" do
    call

    expect(other_sessions).to have_received(:destroy_all)
  end

  it "keeps the current session" do
    call

    expect(sessions).to have_received(:excluding).with(session)
  end

  context "when the password does not save" do
    let(:saved) { false }

    it "keeps the other sessions" do
      call

      expect(sessions).not_to have_received(:excluding)
    end
  end
end
