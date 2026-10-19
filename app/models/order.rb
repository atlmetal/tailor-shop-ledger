# Work a customer leaves and pays for later: usually a deposit when they leave it, and the rest when it's done.
# Each payment counts the day it arrives. Its jobs take its day and count their materials and units that day,
# but never their price, since the payments do. Cancelling an order deletes it with its jobs and payments.
class Order < ApplicationRecord
  acts_as_tenant :shop

  has_many :jobs, dependent: :delete_all
  has_many :payments, dependent: :delete_all

  normalizes :customer_name, with: ->(name) { name.squish }

  validates :customer_name, presence: true, length: { maximum: 60 }
  validates :received_on, comparison: { greater_than_or_equal_to: ->(order) { order.shop.started_on }, less_than_or_equal_to: -> { Date.current } }
  validate :received_by_its_first_payment

  after_update -> { jobs.update_all(done_on: received_on) }, if: :saved_change_to_received_on?

  # What its saved jobs charge. Like what's paid, it's read from the database each time, so a job or payment that
  # a form is still building doesn't count, and one saved through another object does.
  def total
    jobs.pluck(:quantity, :price).sum { |quantity, price| quantity * price }
  end

  def paid
    payments.sum(:amount)
  end

  # What the customer still owes.
  def owed
    total - paid
  end

  # Until its payments cover its jobs, and while it has no jobs yet.
  def pending?
    !jobs.exists? || owed.positive?
  end

  private
    def received_by_its_first_payment
      first_paid_on = payments.minimum(:paid_on)
      errors.add(:received_on, :after_payments) if first_paid_on && received_on && received_on > first_paid_on
    end
end
