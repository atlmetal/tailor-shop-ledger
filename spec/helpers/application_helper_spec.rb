require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#tab_to" do
    subject(:tab) { helper.tab_to("Today", path) { tag.svg } }

    let(:path) { "/" }

    before { allow(helper).to receive(:current_page?).with("/").and_return(current) }

    context "when its page is the one shown" do
      let(:current) { true }

      it { is_expected.to have_css("a.tab[href='/'][aria-current='page']", text: "Today") }
      it { is_expected.to have_css("a.tab svg") }
    end

    context "when another page is shown" do
      let(:current) { false }

      it { is_expected.to have_css("a.tab[href='/']:not([aria-current])", text: "Today") }
    end

    context "when its page isn't built yet" do
      let(:path) { nil }
      let(:current) { false }

      it { is_expected.to have_css("span.tab", text: "Today") }
    end
  end

  describe "#day_title" do
    subject(:day_title) { I18n.with_locale(locale) { helper.day_title(Date.new(2026, 10, 20)) } }

    context "in en" do
      let(:locale) { :en }

      it { is_expected.to eq("Tuesday, October 20") }
    end

    context "in es-CO, whose day names are lowercase" do
      let(:locale) { :"es-CO" }

      it { is_expected.to eq("Martes 20 de octubre") }
    end
  end

  describe "#flash_messages" do
    subject(:flash_messages) { helper.flash_messages }

    before { flash[:notice] = "Saved" }

    it { is_expected.to eq('<p class="flash-notice" role="status">Saved</p>') }
  end

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
