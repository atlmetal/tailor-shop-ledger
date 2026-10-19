class ReportsController < ApplicationController
  # The current month, unless the URL names a period. One after the current period, or before the shop's first,
  # isn't found.
  def show
    date = params[:date] ? Date.iso8601(params[:date]) : Date.current
    period = Reports::Period.new(kind: params.fetch(:kind, "month"), date:)
    raise ActionController::RoutingError, "Not Found" unless period.range.overlap?(current_tenant.started_on..Date.current)

    @report = Reports::PeriodFacade.new(shop: current_tenant, period:)
  rescue Date::Error
    raise ActionController::RoutingError, "Not Found"
  end
end
