module Results
  # The services that left the most in a period, by what their jobs charged less their materials, with their units.
  # A tie goes to the service with more units, and then to the one added first.
  class TopServicesQuery < ApplicationQuery
    Row = Data.define(:service, :units, :left)

    def initialize(period:, limit: 5)
      @period = period
      @limit = limit
    end

    def call
      units, left = Job[:quantity].sum, (Job[:quantity] * (Job[:price] - Job[:material_cost])).sum
      rows = Job.where(done_on: @period).group(:service_id).order(left.desc, units.desc, :service_id).limit(@limit).pluck(:service_id, units, left)
      services = Service.where(id: rows.map(&:first)).index_by(&:id)

      rows.map { |service_id, units, left| Row.new(service: services.fetch(service_id), units:, left:) }
    end
  end
end
