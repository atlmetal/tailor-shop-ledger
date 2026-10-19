FactoryBot.define do
  factory :payment do
    order { association :order, :with_job }
    shop { order.shop }
    paid_on { order.received_on }
    amount { 20_000 }

    # require_tenant: build and save inside the record's own shop, whatever the current one is.
    initialize_with { ActsAsTenant.with_tenant(shop) { new(order:) } }
    to_create { |payment| ActsAsTenant.with_tenant(payment.shop) { payment.save! } }
  end
end
