module Shops
  # Operator tool behind `bin/rails shops:create`: a shop and its user, all or nothing,
  # with a generated password that is returned once.
  class CreateService < ApplicationService
    Result = Data.define(:shop, :user, :password)

    def initialize(name:, started_on:, user_name:, user_email:)
      @name = name
      @started_on = started_on
      @user_name = user_name
      @user_email = user_email
    end

    def call
      password = SecureRandom.base58(16)

      Shop.transaction do
        shop = Shop.create!(name: @name, started_on: @started_on)
        user = User.create!(shop:, name: @user_name, email_address: @user_email, password:)
        Result.new(shop:, user:, password:)
      end
    end
  end
end
