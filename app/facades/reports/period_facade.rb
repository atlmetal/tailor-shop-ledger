module Reports
  # The Reports page: a period's result and how it's calculated, the way to the periods around it and to the other
  # kinds of period, and the services that left the most in it.
  class PeriodFacade
    attr_reader :period

    delegate :kind, to: :period
    delegate :days, to: :result

    def initialize(shop:, period:)
      @shop = shop
      @period = period
    end

    def result
      @result ||= Results::PeriodQuery.call(shop: @shop, period: period.range)
    end

    def in_progress?
      period.range.cover?(Date.current)
    end

    # None before the shop's first period.
    def previous
      period.previous if period.range.begin > @shop.started_on
    end

    # None after the current one.
    def following
      period.following unless in_progress?
    end

    # The period of a kind that holds the last day counted, so the switch keeps the date being viewed.
    def period_of(kind)
      Period.new(kind:, date: days.end)
    end

    # The fixed costs each work day carries in the month of the last day counted.
    def fixed_costs_month
      @fixed_costs_month ||= FixedCosts::MonthQuery.call(shop: @shop, month: days.end)
    end

    def top_services
      @top_services ||= Results::TopServicesQuery.call(period: days)
    end
  end
end
