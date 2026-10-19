# Money a customer pays towards an order: it counts as charged for jobs the day it arrives.
class Payment < ApplicationRecord
  acts_as_tenant :shop

  belongs_to :order

  attribute :amount, PesosType.new

  validates :amount, comparison: { greater_than: 0 }
  validates :paid_on, comparison: { greater_than_or_equal_to: ->(payment) { payment.order.received_on }, less_than_or_equal_to: -> { Date.current } }, if: :order
  validate -> { errors.add(:amount, :more_than_owed) if amount.to_i > owed }, if: :order

  # What the customer owes on the order leaving this payment out: the most it can be.
  def owed
    order.total - order.payments.where.not(id:).sum(:amount)
  end
end
