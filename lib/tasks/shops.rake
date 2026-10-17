namespace :shops do
  desc "Create a shop and its user: NAME='Modistería La Puntada' USER_NAME='Ana Gómez' USER_EMAIL=ana@example.com, plus STARTED_ON=2026-10-01 when its accounts start before today"
  task create: :environment do
    name, user_name, user_email = %w[ NAME USER_NAME USER_EMAIL ].map do |key|
      ENV.fetch(key) { abort "#{key} is missing. Run `bin/rails -D shops:create` for an example." }
    end
    started_on = ENV["STARTED_ON"] ? Date.iso8601(ENV["STARTED_ON"]) : Date.current

    result = Shops::CreateService.call(name:, started_on:, user_name:, user_email:)
    puts "Created #{result.shop.name}, with its accounts from #{result.shop.started_on.iso8601}"
    puts "User: #{result.user.name} <#{result.user.email_address}>"
    puts "Password, shown only now: #{result.password}"
  rescue Date::Error
    abort "STARTED_ON must be a date like 2026-10-01."
  rescue ActiveRecord::RecordInvalid => error
    abort error.record.errors.full_messages.to_sentence
  end
end
