# What the form to add a fixed cost collects: the fixed cost, and its first monthly amount with the month it
# applies from.
class NewFixedCost
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :averaged, :boolean, default: false
  attribute :amount, PesosType.new
  attribute :starts_on, :date

  attr_accessor :shop

  validates :name, presence: true
  validates :amount, comparison: { greater_than_or_equal_to: 0 }
  validates :starts_on, inclusion: { in: :months }

  # The months a change can start from, and the month the shop started when that is earlier: a shop entering
  # its days from paper carries the costs it already had.
  def months
    started = shop.started_on.beginning_of_month
    changes = FixedCostChange.months
    started < changes.first ? [ started, *changes ] : changes
  end
end
