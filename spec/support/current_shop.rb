RSpec.shared_context "with a current shop" do
  let(:shop) { create(:shop) }

  around { |example| ActsAsTenant.with_tenant(shop) { example.run } }
end
