module Today
  # The Today page: the day's goal, which is its share of the fixed costs on a work day, what the shop has made
  # towards it, the day's jobs, and the month so far.
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

    def jobs
      Job.includes(:service).where(done_on: date).order(:id)
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
