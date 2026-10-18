class FixedCostAmount < ApplicationRecord
  acts_as_tenant :shop

  belongs_to :fixed_cost

  attribute :amount, PesosType.new

  validates :amount, comparison: { greater_than_or_equal_to: 0 }
end
