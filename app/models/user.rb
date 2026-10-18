class User < ApplicationRecord
  belongs_to :shop
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password, presence: true, on: :password_change

  # For the operator's rake tasks: easy to read out and to type on a phone, without the l, 1, o and 0
  # that get mixed up.
  def self.generate_password
    SecureRandom.alphanumeric(12, chars: [ *"a".."z", *"0".."9" ] - %w[ l 1 o 0 ])
  end
end
