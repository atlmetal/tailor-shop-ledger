namespace :users do
  desc "Give a user a new password and sign them out everywhere: EMAIL=ana@example.com"
  task new_password: :environment do
    email = ENV.fetch("EMAIL") { abort "EMAIL is missing. Run `bin/rails -D users:new_password` for an example." }
    user = User.find_by(email_address: email) || abort("There is no user with #{email}.")

    password = Users::ResetPasswordService.call(user:)
    puts "New password for #{user.name} <#{user.email_address}>, shown only now: #{password}"
    puts "They were signed out everywhere."
  end
end
