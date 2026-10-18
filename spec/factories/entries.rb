FactoryBot.define do
  factory :entry do
    shop
    kind { "expense" }
    occurred_on { Date.current }
    concept { "Transporte" }
    amount { 12_000 }

    # require_tenant: build and save inside the record's own shop, whatever the current one is.
    initialize_with { ActsAsTenant.with_tenant(shop) { new } }
    to_create { |entry| ActsAsTenant.with_tenant(entry.shop) { entry.save! } }
  end
end
