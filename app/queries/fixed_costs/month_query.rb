module FixedCosts
  # A month's fixed costs: the ones on its list, their total, and the share each of the shop's work days in
  # the month carries, which is the goal Today shows.
  class MonthQuery < ApplicationQuery
    Result = Data.define(:month, :fixed_costs, :total, :work_days) do
      # Rounded to the peso. Every month has some, since a shop works at least one weekday.
      def per_work_day
        (total.to_r / work_days).round
      end
    end

    def initialize(shop:, month:)
      @shop = shop
      @month = month.beginning_of_month
    end

    # In the order they were added. ponytail: picks each fixed cost's amount in Ruby, from its loaded amounts;
    # a shop has a handful of them.
    def call
      fixed_costs = FixedCost.includes(:amounts).order(:id).to_a

      Result.new(
        month: @month,
        fixed_costs: fixed_costs.select { it.listed_on?(@month) },
        total: fixed_costs.sum { it.amount_on(@month) },
        work_days: @shop.work_days_in(@month.all_month)
      )
    end
  end
end
