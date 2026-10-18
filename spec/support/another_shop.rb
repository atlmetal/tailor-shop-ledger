# Request specs, for every controller that reads or writes a shop's records: a request for another
# shop's record finds nothing, so a shop never sees another one or learns that it exists.
RSpec.shared_examples "a record of another shop" do
  it { expect(response).to have_http_status(:not_found) }
end
