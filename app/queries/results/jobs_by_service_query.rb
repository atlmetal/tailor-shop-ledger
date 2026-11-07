module Results
  # A period's jobs by service, each with its units and what its jobs are worth at their price, before materials
  # and paid or not: an order's on the day it was left, as their units count. The most done first; a tie goes to
  # the one worth more, and then to the service added first.
  class JobsByServiceQuery < ApplicationQuery
    Row = Data.define(:service, :units, :worth)

    def initialize(period:)
      @period = period
    end

    def call
      units, worth = Job[:quantity].sum, (Job[:quantity] * Job[:price]).sum
      rows = Job.where(done_on: @period).group(:service_id).order(units.desc, worth.desc, :service_id).pluck(:service_id, units, worth)
      services = Service.where(id: rows.map(&:first)).index_by(&:id)

      rows.map { |service_id, units, worth| Row.new(service: services.fetch(service_id), units:, worth:) }
    end
  end
end
