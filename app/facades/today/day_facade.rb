module Today
  # The Today page: the day's goal, which is its share of the fixed costs on a work day, what the shop has made
  # towards it, the day's records, the orders still owed for, and the month so far.
  class DayFacade
    attr_reader :date

    delegate :charged, :materials, :units, to: :day

    def initialize(shop:, date: Date.current)
      @shop = shop
      @date = date
    end

    def work_day?
      @shop.work_days.include?(date.wday)
    end

    # Today's share of the fixed costs; nothing on a day the shop doesn't work.
    def goal
      day.fixed_costs
    end

    # What the jobs charged less their materials: what the shop has made towards the goal.
    def made
      charged - materials
    end

    def left
      [ goal - made, 0 ].max
    end

    def surplus
      [ made - goal, 0 ].max
    end

    # How much of the goal is made, from 0 to 1.
    def progress
      goal.zero? ? 0 : (made.to_r / goal).clamp(0, 1)
    end

    # The day's jobs on their own; an order's show under the order.
    def jobs
      Job.includes(:service).where(done_on: date, order: nil).order(:id)
    end

    # The orders left that day, with their jobs.
    def orders
      Order.includes(:jobs).where(received_on: date).order(:id)
    end

    # The payments that came in for orders that day.
    def payments
      Payment.includes(:order).where(paid_on: date).order(:id)
    end

    # The orders still owed for, the oldest first, each with what's owed.
    def pending_orders
      @pending_orders ||= Orders::PendingQuery.call
    end

    # What they come to.
    def owed
      pending_orders.sum(&:owed)
    end

    def month
      @month ||= Results::PeriodQuery.call(shop: @shop, period: date.all_month)
    end

    private
      def day
        @day ||= Results::PeriodQuery.call(shop: @shop, period: date..date)
      end
  end
end
