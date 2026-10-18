# What the change form in a fixed cost's row collects: its new monthly amount and the month it applies from,
# or a removal from that month, which is a change to 0.
class FixedCostChange
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :amount, PesosType.new
  attribute :starts_on, :date
  attribute :remove, :boolean, default: false

  attr_accessor :fixed_cost

  validates :amount, comparison: { greater_than_or_equal_to: 0 }
  validates :starts_on, inclusion: { in: ->(_change) { months } }

  # A change applies from the current month or one of the next two, never an earlier one.
  def self.months(today = Date.current)
    Array.new(3) { today.beginning_of_month.next_month(it) }
  end

  def amount
    remove ? 0 : super
  end
end
