ActsAsTenant.configure do |config|
  # Any query on a shop-owned model without a current shop raises, in requests, jobs, rake tasks and the console.
  config.require_tenant = true
end
