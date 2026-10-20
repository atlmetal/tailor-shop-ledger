# A customer who pays a sum up front and brings work until it runs out, and then another sum. What they give, its
# top-ups, never counts: it's still theirs, for work not done yet. Each of its jobs counts as a job on its own,
# the day it's done, even past the balance, when the customer owes the difference until the next top-up.
class Advance < ApplicationRecord
  acts_as_tenant :shop

  # Its jobs counted, so it's deleted only while it has none. Its top-ups never did, and go with it.
  has_many :jobs, -> { order(done_on: :desc, id: :desc) }, dependent: :restrict_with_error
  has_many :top_ups, -> { order(paid_on: :desc, id: :desc) }, dependent: :delete_all

  normalizes :customer_name, with: ->(name) { name.squish }

  validates :customer_name, presence: true, length: { maximum: 60 }
  validates_uniqueness_to_tenant :customer_name, case_sensitive: false

  # What its top-ups add up to. Like what its jobs charge, it's read from the database each time, as on an order.
  def given
    top_ups.sum(:amount)
  end

  def charged
    jobs.pluck(:quantity, :price).sum { |quantity, price| quantity * price }
  end

  # What's left of what the customer gave; below 0, what they owe.
  def balance
    given - charged
  end

  # The day of its first top-up or job; none while it has neither.
  def since
    [ top_ups.minimum(:paid_on), jobs.minimum(:done_on) ].compact.min
  end
end
