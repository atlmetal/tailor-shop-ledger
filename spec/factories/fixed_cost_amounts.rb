FactoryBot.define do
  factory :fixed_cost_amount do
    fixed_cost
    shop { fixed_cost.shop }
    starts_on { Date.current.beginning_of_month }
    amount { 900_000 }

    # require_tenant: build and save inside the record's own shop, whatever the current one is.
    initialize_with { ActsAsTenant.with_tenant(shop) { new } }
    to_create { |amount| ActsAsTenant.with_tenant(amount.shop) { amount.save! } }
  end
end
