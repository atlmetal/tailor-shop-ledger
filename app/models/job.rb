# A piece of work for a customer. On its own, it's recorded the day they pay for it; in an order, which they pay
# for in parts, it takes the order's day and never counts its price, since the order's payments do. Its price and
# material cost are per unit and its own: copied from its service when it's recorded, so changing the service
# never changes the job.
class Job < ApplicationRecord
  acts_as_tenant :shop

  belongs_to :service
  belongs_to :order, optional: true

  attribute :price, PesosType.new
  attribute :material_cost, PesosType.new

  after_initialize :copy_from_service, if: :new_record?
  before_validation -> { self.done_on = order.received_on }, if: :order
  before_destroy :keep_order_payments_covered, if: :order

  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :price, :material_cost, comparison: { greater_than_or_equal_to: 0 }
  validates :done_on, comparison: { greater_than_or_equal_to: ->(job) { job.shop.started_on }, less_than_or_equal_to: -> { Date.current } }
  validate -> { errors.add(:base, :less_than_paid) if other_jobs_charged + charged < order.paid }, if: :order

  def charged
    quantity.to_i * price.to_i
  end

  def materials
    quantity.to_i * material_cost.to_i
  end

  def leaves
    charged - materials
  end

  private
    # The price and material cost the user doesn't give come from the service.
    def copy_from_service
      return unless service

      self.price ||= service.price
      self.material_cost ||= service.material_cost
    end

    # What the order's other jobs charge, which with this one's must cover what the customer has paid.
    def other_jobs_charged
      order.total - quantity_in_database.to_i * price_in_database.to_i
    end

    def keep_order_payments_covered
      return if other_jobs_charged >= order.paid

      errors.add(:base, :less_than_paid)
      throw :abort
    end
end
