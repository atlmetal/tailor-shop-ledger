# A piece of work for a customer, recorded the day they pay for it. Its price and material cost are per unit
# and its own: copied from its service when it's recorded, so changing the service never changes the job.
class Job < ApplicationRecord
  acts_as_tenant :shop

  belongs_to :service

  attribute :price, PesosType.new
  attribute :material_cost, PesosType.new

  after_initialize :copy_from_service, if: :new_record?

  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :price, :material_cost, comparison: { greater_than_or_equal_to: 0 }
  validates :done_on, comparison: { greater_than_or_equal_to: ->(job) { job.shop.started_on }, less_than_or_equal_to: -> { Date.current } }

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
end
