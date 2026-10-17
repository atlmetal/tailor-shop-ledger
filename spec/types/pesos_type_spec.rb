require "rails_helper"

RSpec.describe PesosType do
  subject(:pesos) { described_class.new.cast(value) }

  context "with digits" do
    let(:value) { "50000" }

    it { is_expected.to eq(50_000) }
  end

  context "with the formatting of a money field in es-CO" do
    let(:value) { "$1.234.567" }

    it { is_expected.to eq(1_234_567) }
  end

  context "with the formatting of a money field in en" do
    let(:value) { "$1,234,567" }

    it { is_expected.to eq(1_234_567) }
  end

  context "with an integer" do
    let(:value) { 15_000 }

    it { is_expected.to eq(15_000) }
  end

  context "with a decimal part" do
    let(:value) { "120.450,00" }

    it { is_expected.to be_nil }
  end

  context "with a minus sign" do
    let(:value) { "-5000" }

    it { is_expected.to be_nil }
  end

  context "with a separator that doesn't group thousands" do
    let(:value) { "50.0000" }

    it { is_expected.to be_nil }
  end

  context "with mixed separators" do
    let(:value) { "1.234,567" }

    it { is_expected.to be_nil }
  end

  context "with more pesos than an integer column holds" do
    let(:value) { "3.000.000.000" }

    it { is_expected.to be_nil }
  end

  context "with a blank field" do
    let(:value) { "" }

    it { is_expected.to be_nil }
  end
end
