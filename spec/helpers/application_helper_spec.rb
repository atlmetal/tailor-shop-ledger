require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#field_error" do
    subject(:field_error) { helper.field_error(record, :name) }

    let(:record) { instance_double(User, errors:) }
    let(:errors) { instance_double(ActiveModel::Errors, "[]": messages, full_messages_for: [ "Name can't be blank" ]) }

    context "when the attribute has errors" do
      let(:messages) { [ "can't be blank" ] }

      it { is_expected.to eq(%(<p class="field-error">Name can&#39;t be blank</p>)) }
    end

    context "when the attribute has no errors" do
      let(:messages) { [] }

      it { is_expected.to be_nil }
    end
  end
end
