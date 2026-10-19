FactoryBot.define do
  factory :order do
    shop
    customer_name { "Marta Rodríguez" }
    received_on { Date.current }

    # require_tenant: build and save inside the record's own shop, whatever the current one is.
    initialize_with { ActsAsTenant.with_tenant(shop) { new } }
    to_create { |order| ActsAsTenant.with_tenant(order.shop) { order.save! } }

    # One job charging 50,000, so payments up to that are valid.
    trait :with_job do
      after(:create) { |order| create(:job, order:, service: create(:service, shop: order.shop, price: 50_000)) }
    end
  end
end
