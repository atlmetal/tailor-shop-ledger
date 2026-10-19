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

    context "with a message a page shows in place" do
      before { flash[:saved] = "2 × Basta de pantalón, $16,000" }

      it { is_expected.to eq('<p class="flash-notice" role="status">Saved</p>') }
    end
  end

  describe "#record_date_field" do
    subject(:field) { helper.form_with(scope: :job, url: "/jobs") { |form| helper.record_date_field(form, :done_on) } }

    before do
      travel_to Date.new(2026, 10, 20)
      allow(helper).to receive(:current_tenant).and_return(instance_double(Shop, started_on: Date.new(2026, 8, 3)))
    end

    it { is_expected.to have_css("input[type='date'][name='job[done_on]'][min='2026-08-03'][max='2026-10-20'][required]") }
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
