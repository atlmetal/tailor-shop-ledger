# What a shop pays every month, whether it works or not. Its amounts each apply from a month on, so changing
# one never changes the months before it. The methods below read the loaded amounts; months are first days.
class FixedCost < ApplicationRecord
  acts_as_tenant :shop

  has_many :amounts, -> { order(:starts_on) }, class_name: "FixedCostAmount", inverse_of: :fixed_cost

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true

  # The latest amount that starts by the month; 0 before the first one.
  def amount_on(month)
    amounts.select { it.starts_on <= month }.last&.amount || 0
  end

  # The first change scheduled after the month.
  def change_after(month)
    amounts.find { it.starts_on > month }
  end

  # Whether the month's amount is a change from that very month, which leaves an earlier amount behind.
  def changed_on?(month)
    amounts.any? { it.starts_on == month } && amounts.first.starts_on < month
  end

  # A fixed cost leaves the month's list once it's 0 from that month on with no later change: removed.
  def listed_on?(month)
    amount_on(month).positive? || change_after(month).present?
  end
end
