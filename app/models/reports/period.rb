module Reports
  # A period of the reports, named by its kind and any of its days: a day, a week from Monday to Sunday, a month,
  # a semester (January to June or July to December) or a year.
  class Period < Data.define(:kind, :date)
    KINDS = %w[ day week month semester year ].freeze

    def range
      case kind
      when "day" then date..date
      when "week" then date.all_week
      when "month" then date.all_month
      when "semester" then semester
      when "year" then date.all_year
      end
    end

    def previous
      with(date: range.begin.prev_day)
    end

    def following
      with(date: range.end.next_day)
    end

    private
      def semester
        first = Date.new(date.year, date.month > 6 ? 7 : 1)
        first..first.advance(months: 5).end_of_month
      end
  end
end
