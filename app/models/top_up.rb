# A sum a customer gives towards their advance. It never counts: what counts is each job done on it.
class TopUp < ApplicationRecord
  acts_as_tenant :shop

  belongs_to :advance

  attribute :amount, PesosType.new

  validates :amount, comparison: { greater_than: 0 }
  validates :paid_on, comparison: { greater_than_or_equal_to: ->(top_up) { top_up.shop.started_on }, less_than_or_equal_to: -> { Date.current } }

  # What the advance has left leaving this top-up out, below 0 when the customer owes.
  def advance_balance
    advance.balance - amount_in_database.to_i
  end
end
