FactoryBot.define do
  factory :advance do
    shop
    customer_name { "Hotel Almendros" }

    # require_tenant: build and save inside the record's own shop, whatever the current one is.
    initialize_with { ActsAsTenant.with_tenant(shop) { new } }
    to_create { |advance| ActsAsTenant.with_tenant(advance.shop) { advance.save! } }
  end
end
