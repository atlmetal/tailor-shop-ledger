require "rails_helper"

RSpec.describe "Sentry's before_send" do
  subject(:sent) { Sentry.configuration.before_send.call(event, {}) }

  let(:event) { instance_double(Sentry::ErrorEvent, exception: instance_double(Sentry::ExceptionInterface, values: [ exception ])) }
  let(:exception) do
    instance_double(Sentry::SingleExceptionInterface,
      value: "PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint \"index_users_on_email_address\" (ActiveRecord::RecordNotUnique)\n" \
             "DETAIL:  Key (email_address)=(ana@example.com) already exists.\n")
  end

  before { allow(exception).to receive(:value=) }

  it { is_expected.to eq event }

  it "drops the row that PostgreSQL quotes after DETAIL" do
    sent

    expect(exception).to have_received(:value=)
      .with("PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint \"index_users_on_email_address\" (ActiveRecord::RecordNotUnique)\nDETAIL: [Filtered]")
  end

  context "with a message instead of an exception" do
    let(:event) { instance_double(Sentry::ErrorEvent, exception: nil) }

    it { is_expected.to eq event }
  end
end
