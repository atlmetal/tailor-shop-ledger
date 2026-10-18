require "rails_helper"

RSpec.describe ServicesHelper, type: :helper do
  describe "#service_leaves" do
    subject(:leaves) { helper.service_leaves(instance_double(Service, leaves: amount)) }

    context "when the price covers the materials" do
      let(:amount) { 7_500 }

      it { is_expected.to eq('Leaves you <strong class="font-mono">$7,500</strong>') }
    end

    context "when the materials cost more than the price" do
      let(:amount) { -500 }

      it { is_expected.to eq('Leaves you <strong class="font-mono text-loss-ink">−$500</strong>') }
    end
  end

  describe "#inactive_services" do
    subject(:inactive) { helper.inactive_services(services) }

    context "without deactivated services" do
      let(:services) { [] }

      it { is_expected.to be_nil }
    end

    context "with deactivated services" do
      let(:services) { [ instance_double(Service, name: "Cortinas", price: 45_000, to_param: "7") ] }

      it { is_expected.to have_css("details summary", text: "Deactivated (1)") }
      it { is_expected.to have_css("form[action='/services/7/activation'] button", text: "Activate", visible: :all) }
    end
  end
end
