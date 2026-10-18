FactoryBot.define do
  factory :fixed_cost do
    shop
    sequence(:name) { |n| "Gasto fijo #{n}" }

    # require_tenant: build and save inside the record's own shop, whatever the current one is.
    initialize_with { ActsAsTenant.with_tenant(shop) { new } }
    to_create { |fixed_cost| ActsAsTenant.with_tenant(fixed_cost.shop) { fixed_cost.save! } }
  end
end
