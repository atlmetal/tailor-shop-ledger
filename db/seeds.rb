# Demo data: wipes the whole database and builds two demo shops through the app's own services,
# deterministic and relative to today. Every milestone extends it with what it adds.
if Rails.env.production?
  puts "Seeds wipe the database and create accounts with a known password, so they never run in production."
  return
end

require_relative "seeds/demo"

Seeds::Demo.new.run
