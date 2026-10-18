# What the shop pays now and then, like a machine repair (an expense), or gets from something other than a job,
# like selling fabric scraps (other income).
class Entry < ApplicationRecord
  acts_as_tenant :shop

  enum :kind, { expense: "expense", income: "income" }, validate: true

  attribute :amount, PesosType.new

  normalizes :concept, with: ->(concept) { concept.squish }

  validates :concept, presence: true
  validates :amount, comparison: { greater_than: 0 }
  validates :occurred_on, comparison: { greater_than_or_equal_to: ->(entry) { entry.shop.started_on }, less_than_or_equal_to: -> { Date.current } }

  scope :latest, -> { order(occurred_on: :desc, id: :desc).limit(10) }
end
