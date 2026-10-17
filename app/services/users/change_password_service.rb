module Users
  # Changes the signed-in user's password and signs out their other sessions,
  # so a leaked password stops working everywhere else at once.
  class ChangePasswordService < ApplicationService
    def initialize(session:, attributes:)
      @session = session
      @attributes = attributes
    end

    def call
      user = @session.user
      user.assign_attributes(@attributes)
      user.sessions.excluding(@session).destroy_all if user.save(context: :password_change)
      user
    end
  end
end
