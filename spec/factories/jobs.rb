FactoryBot.define do
  factory :job do
    service
    shop { service.shop }
    done_on { Date.current }
    quantity { 1 }

    # require_tenant: build and save inside the record's own shop, whatever the current one is.
    initialize_with { ActsAsTenant.with_tenant(shop) { new(service:) } }
    to_create { |job| ActsAsTenant.with_tenant(job.shop) { job.save! } }
  end
end
