# Production errors go to Sentry once SENTRY_DSN is set. The SDK's defaults keep personal data out:
# no request bodies, query strings, cookies, IPs, SQL values or job arguments. PostgreSQL's errors
# quote the conflicting row after DETAIL, such as a user's email address, so that part stays out too.
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[ production ]
  config.before_send = lambda do |event, _hint|
    event.exception&.values&.each { |exception| exception.value = exception.value.sub(/^DETAIL:.*/m, "DETAIL: [Filtered]") }
    event
  end
end
