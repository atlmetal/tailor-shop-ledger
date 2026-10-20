FactoryBot.define do
  factory :top_up do
    advance
    shop { advance.shop }
    paid_on { Date.current }
    amount { 100_000 }

    # require_tenant: build and save inside the record's own shop, whatever the current one is.
    initialize_with { ActsAsTenant.with_tenant(shop) { new(advance:) } }
    to_create { |top_up| ActsAsTenant.with_tenant(top_up.shop) { top_up.save! } }
  end
end
