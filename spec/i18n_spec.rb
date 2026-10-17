require "rails_helper"

RSpec.describe "Locale files" do
  let(:translations) do
    Rails.root.glob("config/locales/*.yml").map { |file| YAML.load_file(file) }.reduce({}, :deep_merge)
  end
  let(:en_keys) { translations.fetch("en").deep_transform_values { nil } }
  let(:es_co_keys) { translations.fetch("es-CO").deep_transform_values { nil } }

  it "define the same keys in en and es-CO" do
    expect(es_co_keys).to eq(en_keys)
  end
end
