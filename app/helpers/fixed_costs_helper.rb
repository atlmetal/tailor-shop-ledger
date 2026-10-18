module FixedCostsHelper
  # The lines under a fixed cost's name: "Promedio", and the change scheduled after the month, or else the amount
  # it had until the month before when it changed from this one.
  def fixed_cost_notes(fixed_cost, month)
    notes = [ (t("fixed_costs.fixed_cost.averaged") if fixed_cost.averaged?), fixed_cost_change_note(fixed_cost, month) ]
    safe_join(notes.compact.map { tag.span(it, class: "text-meta text-graphite") })
  end

  # One line per month a change can start from, saying which months keep which amount. The change form shows
  # the line of the month selected.
  def change_helps(fixed_cost, months)
    current, previous = months.first, months.first.prev_month

    months.each_index.map do |index|
      if index.zero?
        t("fixed_costs.change_form.help_now", month: month_name(current).upcase_first, previous: month_name(previous).upcase_first,
          amount: pesos(fixed_cost.amount_on(previous)))
      else
        t("fixed_costs.change_form.help_later", months: months.first(index).map { month_name(it) }.join(", ").upcase_first,
          amount: pesos(fixed_cost.amount_on(current)))
      end
    end
  end

  # The months to choose from, "octubre de 2026"; the month the shop started says so.
  def month_options(months, started_on: nil)
    months.map do |month|
      label = l(month, format: :month_year)
      label = t("fixed_costs.new_fixed_cost.started", month: label) if month == started_on&.beginning_of_month && month < Date.current.beginning_of_month
      [ label, month.iso8601 ]
    end
  end

  # One toggle per weekday, Monday first. Each saves the work days with its day flipped: "" keeps the list in
  # the request when no day is left, so the shop is told to mark one.
  def work_day_buttons(shop)
    [ 1, 2, 3, 4, 5, 6, 0 ].map do |wday|
      on = shop.work_days.include?(wday)
      days = on ? shop.work_days - [ wday ] : shop.work_days + [ wday ]

      button_to t("date.abbr_day_names")[wday].first(2).upcase_first, work_days_path, method: :patch, class: "work-day",
        params: { shop: { work_days: [ "", *days ] } }, aria: { pressed: on, label: t("date.day_names")[wday].upcase_first }
    end
  end

  # How many days the shop works this month and what each one must cover, or what to do with no day marked.
  def work_days_summary(month)
    return tag.p(month.shop.errors.messages_for(:work_days).to_sentence, class: "text-note") if month.shop.errors.include?(:work_days)

    safe_join([
      tag.p(t("fixed_costs.work_days.works_html", month: month_name(month.month), days: tag.strong(t("fixed_costs.work_days.days", count: month.work_days))), class: "text-note"),
      tag.p(pesos(month.per_work_day), class: "font-mono text-title leading-[1.15] font-bold tracking-[-0.02em]"),
      tag.p(t("fixed_costs.work_days.goal"), class: "text-meta text-graphite")
    ])
  end

  private
    def fixed_cost_change_note(fixed_cost, month)
      if (change = fixed_cost.change_after(month))
        return t("fixed_costs.fixed_cost.removed_from", month: month_name(change.starts_on)) if change.amount.zero?

        t("fixed_costs.fixed_cost.from", month: month_name(change.starts_on), amount: pesos(change.amount))
      elsif fixed_cost.changed_on?(month)
        t("fixed_costs.fixed_cost.until", month: month_name(month.prev_month), amount: pesos(fixed_cost.amount_on(month.prev_month)))
      end
    end
end
