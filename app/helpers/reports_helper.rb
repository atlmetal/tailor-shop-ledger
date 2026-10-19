module ReportsHelper
  # The kinds of period, each opening its period that holds the last day counted; the kind shown is marked.
  def period_links(report)
    Reports::Period::KINDS.map do |kind|
      link_to t("reports.show.kinds.#{kind}"), report_path_for(report.period_of(kind)), aria: { current: ("page" if kind == report.kind) }
    end
  end

  # An arrow to the period before or after, dimmed where there's none: before the shop's first period, and after
  # the current one.
  def period_arrow(period, label, &icon)
    content = capture(&icon)
    return tag.span(content, role: "link", aria: { label:, disabled: true }, class: "period-arrow") unless period

    link_to content, report_path_for(period), aria: { label: }, class: "period-arrow"
  end

  def report_path_for(period)
    report_path(period.kind, period.range.begin)
  end

  # "Martes 20 de octubre", "Del 19 al 25 de octubre", "Octubre de 2026", "Segundo semestre de 2026" or "2026".
  def period_title(period)
    first = period.range.begin

    case period.kind
    when "day" then day_title(first)
    when "week" then days_range(period.range)
    when "month" then l(first, format: :month_year).upcase_first
    when "semester" then t("reports.show.semester.#{first.month == 1 ? "first" : "second"}", year: first.year)
    when "year" then first.year.to_s
    end
  end

  # The days counted where the title doesn't say them, and whether they reach today: "Del 1 al 20, hasta hoy", or
  # on today's report, "Hoy, hasta ahora". A week says them only when the shop started in it.
  def period_detail(report)
    days = report.days

    case report.kind
    when "day"
      t("reports.show.today_so_far") if report.in_progress?
    when "week"
      if days.begin != report.period.range.begin then so_far(days_range(days), report)
      elsif report.in_progress? then t("reports.show.so_far")
      end
    when "month"
      so_far(t("reports.show.days", from: days.begin.day, to: days.end.day, month: month_name(days.end)), report)
    else
      so_far(days_range(days), report)
    end
  end

  # "17 días trabajados · 112 trabajos".
  def result_summary(result)
    [ t("reports.result.work_days", count: result.work_days), t("reports.result.units", count: result.units) ].join(" · ")
  end

  def calculation_line(label, amount)
    tag.div(safe_join([ tag.span(label), tag.span(amount, class: "font-mono font-medium") ], " "), class: "flex min-h-11 items-center justify-between gap-3")
  end

  # A day's records, only on a day's report.
  def day_records(report)
    render("reports/day_records", report:) if report.day?
  end

  # Each record opening its form or its order, or a line saying the day has none.
  def day_record_rows(report)
    rows = [ *record_rows(report.jobs, report.orders, report.payments), render(partial: "reports/entry", collection: report.entries, as: :entry) ].compact
    return tag.p(t("reports.day_records.none"), class: "mt-2.5 text-note text-graphite") if rows.empty?

    tag.div(safe_join(rows), class: "panel mt-2.5 divide-y divide-divider")
  end

  # The services that left the most in the period; nothing while it has no jobs, or on a day's report, where they
  # would repeat its records.
  def top_services(report)
    return if report.day?

    rows = report.top_services
    render("reports/top_services", rows:) if rows.any?
  end

  # What a service left, in the loss color when its materials cost more than it charged.
  def top_service_left(row)
    tag.span(pesos(row.left), class: token_list("shrink-0 font-mono text-lg font-bold", "text-loss-ink": row.left.negative?))
  end

  # "Octubre, hasta hoy" for the current month, so it isn't compared as if it were complete; "Septiembre" otherwise.
  def month_label(month)
    name = month_name(month).upcase_first
    month == Date.current.beginning_of_month ? t("reports.months.so_far", month: name) : name
  end

  # What a line of the calculation takes off the result, "−$151.400", even when it's 0.
  def pesos_off(amount)
    "−#{number_to_currency(amount, precision: 0)}"
  end

  # What a line of the calculation adds to the result, "+$20.000".
  def pesos_on(amount)
    "+#{number_to_currency(amount, precision: 0)}"
  end

  private
    # "Del 19 al 25 de octubre", or across months, "Del 28 de septiembre al 4 de octubre".
    def days_range(days)
      if days.begin.month == days.end.month
        t("reports.show.range.same_month", from: days.begin.day, to: days.end.day, month: month_name(days.end))
      else
        t("reports.show.range.months", from: l(days.begin, format: :day_month), to: l(days.end, format: :day_month))
      end
    end

    def so_far(range, report)
      report.in_progress? ? t("reports.show.range_so_far", range:) : range
    end
end
