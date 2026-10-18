require "rails_helper"

RSpec.describe "Fixed costs", type: :request do
  include_context "with a signed-in user"
  include_context "with a test tenant"

  let(:september) { Date.new(2026, 9, 1) }
  let(:october) { Date.new(2026, 10, 1) }
  let(:november) { Date.new(2026, 11, 1) }
  let(:rent) { create(:fixed_cost, shop:, name: "Arriendo del local") }
  let(:rent_amounts) { rent.reload.amounts.map { [ it.starts_on, it.amount ] } }

  before do
    travel_to Date.new(2026, 10, 20)
    create(:fixed_cost_amount, fixed_cost: rent, starts_on: september, amount: 900_000)
  end

  describe "GET /fixed_costs" do
    before do
      create(:fixed_cost_amount, fixed_cost: create(:fixed_cost, name: "Arriendo de enfrente"), starts_on: september)
      get fixed_costs_path
    end

    it { expect(response.parsed_body.at("summary").text.squish).to eq("Arriendo del local $900,000 Now: $900,000") }
    it { expect(response.body).to include("Total for October") }
    it { expect(response.body).not_to include("Arriendo de enfrente") }
  end

  describe "POST /fixed_costs" do
    let(:new_fixed_cost_params) { { name: "Luz", averaged: "1", amount: "120,000", starts_on: "2026-11-01" } }

    before { post fixed_costs_path, params: { new_fixed_cost: new_fixed_cost_params } }

    it { expect(response).to redirect_to(fixed_costs_path) }
    it { expect(FixedCost.find_by!(name: "Luz")).to be_averaged }
    it { expect(FixedCost.find_by!(name: "Luz").amounts.map { [ it.starts_on, it.amount ] }).to eq([ [ november, 120_000 ] ]) }

    context "without a name" do
      let(:new_fixed_cost_params) { super().merge(name: "") }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(response.parsed_body.at("details[open] form[action='#{fixed_costs_path}']")).to be_present }
      it { expect(FixedCost.count).to eq(1) }
    end
  end

  describe "PATCH /fixed_costs/:id" do
    let(:change_params) { { amount: "950,000", starts_on: "2026-11-01" } }

    before { patch fixed_cost_path(rent), params: { fixed_cost_change: change_params } }

    context "from a later month" do
      it { expect(response).to redirect_to(fixed_costs_path) }
      it("leaves the current month alone") { expect(rent_amounts).to eq([ [ september, 900_000 ], [ november, 950_000 ] ]) }
    end

    context "from a month that already has a change" do
      before { patch fixed_cost_path(rent), params: { fixed_cost_change: change_params.merge(amount: "975,000") } }

      it("replaces that change") { expect(rent_amounts).to eq([ [ september, 900_000 ], [ november, 975_000 ] ]) }
    end

    context "when it removes the fixed cost from this month" do
      let(:change_params) { { amount: "", starts_on: "2026-10-01", remove: "1" } }

      it { expect(rent_amounts).to eq([ [ september, 900_000 ], [ october, 0 ] ]) }

      it "takes it off the list" do
        get fixed_costs_path

        expect(response.body).not_to include("Arriendo del local")
      end
    end

    context "without an amount" do
      let(:change_params) { super().merge(amount: "") }

      it { expect(response).to have_http_status(:unprocessable_content) }
      it { expect(response.parsed_body.at("details[open] .field-error").text).to eq("New monthly amount can't be blank") }
      it { expect(rent_amounts).to eq([ [ september, 900_000 ] ]) }
    end
  end

  describe "PATCH /fixed_costs/:id of another shop" do
    let(:outsider) { create(:fixed_cost) }

    before do
      create(:fixed_cost_amount, fixed_cost: outsider, starts_on: september, amount: 900_000)
      patch fixed_cost_path(outsider), params: { fixed_cost_change: { amount: "1", starts_on: "2026-11-01" } }
    end

    it_behaves_like "a record of another shop"
    it { expect(ActsAsTenant.with_tenant(outsider.shop) { outsider.reload.amounts.map(&:amount) }).to eq([ 900_000 ]) }
  end
end
