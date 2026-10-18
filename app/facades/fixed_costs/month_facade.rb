module FixedCosts
  # The fixed costs page: this month's list and total, and the forms to change a fixed cost or add one, which
  # come back open with their errors when they fail.
  class MonthFacade
    attr_reader :new_fixed_cost

    delegate :month, :fixed_costs, :total, :work_days, :per_work_day, to: :summary

    def initialize(shop:, today: Date.current, change: nil, new_fixed_cost: nil)
      @shop = shop
      @today = today
      @change = change
      @new_fixed_cost = new_fixed_cost || NewFixedCost.new(shop:, starts_on: today.beginning_of_month)
    end

    # The form in the fixed cost's row, from next month unless it came back with errors.
    def change_for(fixed_cost)
      return @change if @change&.fixed_cost == fixed_cost

      FixedCostChange.new(fixed_cost:, starts_on: @today.beginning_of_month.next_month)
    end

    def change_months
      FixedCostChange.months(@today)
    end

    private
      def summary
        @summary ||= MonthQuery.call(shop: @shop, month: @today)
      end
  end
end
