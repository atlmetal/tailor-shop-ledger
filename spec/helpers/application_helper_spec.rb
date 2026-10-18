require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#tab_to" do
    subject(:tab) { helper.tab_to("Today", path) { tag.svg } }

    let(:path) { "/" }
    let(:request) { instance_double(ActionDispatch::Request, path: shown_path) }
    let(:shown_path) { "/" }

    before { allow(helper).to receive(:request).and_return(request) }

    context "when its page is the one shown" do
      it { is_expected.to have_css("a.tab[href='/'][aria-current='page']", text: "Today") }
      it { is_expected.to have_css("a.tab svg") }
    end

    context "when another page is shown" do
      let(:shown_path) { "/account" }

      it { is_expected.to have_css("a.tab[href='/']:not([aria-current])", text: "Today") }
    end

    context "when its page isn't built yet" do
      let(:path) { nil }

      it { is_expected.to have_css("span.tab", text: "Today") }
    end
  end

  describe "#aria_current" do
    subject(:aria_current) { helper.aria_current("/services") }

    let(:request) { instance_double(ActionDispatch::Request, path: shown_path) }

    before { allow(helper).to receive(:request).and_return(request) }

    context "on the page itself" do
      let(:shown_path) { "/services" }

      it { is_expected.to eq("page") }
    end

    context "on a page of its section" do
      let(:shown_path) { "/services/12/edit" }

      it { is_expected.to eq("page") }
    end

    context "on a page whose path only starts the same" do
      let(:shown_path) { "/services_report" }

      it { is_expected.to be_nil }
    end
  end

  describe "#pesos" do
    it { expect(helper.pesos(1_234_567)).to eq("$1,234,567") }
    it { expect(helper.pesos(-47_000)).to eq("−$47,000") }
    it { expect(I18n.with_locale(:"es-CO") { helper.pesos(1_234_567) }).to eq("$1.234.567") }
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
