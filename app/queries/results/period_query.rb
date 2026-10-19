module Results
  # What a shop made in a period: what its jobs on their own charged and the payments that came in for orders, the
  # materials and units of every job, an order's on the day it was left; its other income and expenses; and the
  # fixed costs of its work days. Only days from the shop's start to today count, so a period in progress counts
  # up to today, today included, and nothing before the shop started.
  class PeriodQuery < ApplicationQuery
    Result = Data.define(:days, :charged, :materials, :incomes, :expenses, :fixed_costs, :work_days, :units) do
      # From 0 up a profit, below 0 a loss.
      def total
        charged - materials + incomes - expenses - fixed_costs
      end
    end

    def initialize(shop:, period:)
      @shop = shop
      @days = [ period.begin, shop.started_on ].max..[ period.end, Date.current ].min
    end

    def call
      # An order's jobs never count their price: its payments do.
      units, charged, materials = Job.where(done_on: @days)
        .pick(Job[:quantity].sum, (Job[:quantity] * Job[:price]).sum.filter(Job[:order_id].eq(nil)), (Job[:quantity] * Job[:material_cost]).sum)
      paid = Payment.where(paid_on: @days).sum(:amount)
      entries = Entry.where(occurred_on: @days).group(:kind).sum(:amount)

      Result.new(days: @days, charged: charged.to_i + paid, materials: materials.to_i, incomes: entries.fetch("income", 0), expenses: entries.fetch("expense", 0),
        fixed_costs:, work_days: @shop.work_days_in(@days), units: units.to_i)
    end

    private
      # Each month the period touches carries its fixed costs × the period's work days in it ÷ its work days,
      # rounded to the peso: a whole month carries exactly its fixed costs.
      def fixed_costs
        @days.group_by(&:beginning_of_month).sum do |month, days|
          month_costs = FixedCosts::MonthQuery.call(shop: @shop, month:)
          (month_costs.total.to_r * @shop.work_days_in(days) / month_costs.work_days).round
        end
      end
  end
end
