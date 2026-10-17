module Users
  # Operator tool behind `bin/rails users:new_password`: a generated password, returned once,
  # and every session of the user signed out, so the old password stops working everywhere.
  class ResetPasswordService < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      password = SecureRandom.base58(16)

      User.transaction do
        @user.update!(password:)
        @user.sessions.destroy_all
      end
      password
    end
  end
end
