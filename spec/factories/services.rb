FactoryBot.define do
  factory :service do
    shop
    sequence(:name) { |n| "Servicio #{n}" }
    price { 8_000 }
    material_cost { 500 }

    # require_tenant: build and save inside the record's own shop, whatever the current one is.
    initialize_with { ActsAsTenant.with_tenant(shop) { new } }
    to_create { |service| ActsAsTenant.with_tenant(service.shop) { service.save! } }
  end
end
