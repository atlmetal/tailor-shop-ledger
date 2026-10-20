require "rails_helper"

RSpec.describe "The parameters kept out of the logs" do
  subject(:logged) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(params) }

  let(:params) { { "order" => { "customer_name" => "Marta Rodríguez", "received_on" => "2026-10-15" } } }

  it("leave out the customer's name") { is_expected.to eq("order" => { "customer_name" => "[FILTERED]", "received_on" => "2026-10-15" }) }

  context "with an advance" do
    let(:params) { { "advance" => { "customer_name" => "Hotel Almendros" } } }

    it("leave out the customer's name") { is_expected.to eq("advance" => { "customer_name" => "[FILTERED]" }) }
  end
end
