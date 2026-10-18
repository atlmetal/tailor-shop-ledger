# Request specs: lets setup and expectations query the signed-in user's shop. The middleware in
# config/environments/test.rb clears it during each request, so the app finds the shop itself.
RSpec.shared_context "with a test tenant" do
  let(:shop) { user.shop }

  before { ActsAsTenant.test_tenant = shop }
  after { ActsAsTenant.test_tenant = nil }
end
