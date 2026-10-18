class Service < ApplicationRecord
  acts_as_tenant :shop

  attribute :price, PesosType.new
  attribute :material_cost, PesosType.new

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true
  validates_uniqueness_to_tenant :name, case_sensitive: false, conditions: -> { where(active: true) }, if: :active?
  validates :price, :material_cost, comparison: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # What the service leaves once its materials are paid: "Te deja".
  def leaves
    price - material_cost
  end
end
