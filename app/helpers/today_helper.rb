module TodayHelper
  # The goal and how much of it is made, on a work day; on a day off, that there's no goal and what was made.
  def goal_panel(day)
    render(day.work_day? ? "today/goal" : "today/day_off", day:)
  end

  # How far the tape fills, as a CSS width.
  def goal_bar_width(day)
    "#{(day.progress * 100).to_f.round(1)}%"
  end

  def goal_percent(day)
    (day.progress * 100).floor
  end

  # How much is left to cover the day's fixed costs, or by how much they're covered, and what makes up the day.
  def goal_note(day)
    covered =
      if day.left.positive?
        t("today.goal.left_html", left: pesos(day.left))
      elsif day.surplus.positive?
        t("today.goal.surplus_html", surplus: pesos(day.surplus))
      else
        t("today.goal.covered_html")
      end

    safe_join([ covered, t("today.goal.made_from", charged: pesos(day.charged), materials: pesos(day.materials)) ], " ")
  end

  # Today's records, each opening its form or its order; a line saying there are none yet otherwise.
  def today_records(day)
    rows = record_rows(day.jobs, day.orders, day.payments)
    return tag.p(t("today.show.no_jobs"), class: "mt-2.5 text-note text-graphite") if rows.empty?

    tag.div(safe_join(rows), class: "panel mt-2.5 divide-y divide-divider")
  end

  # A day's jobs on their own, the orders left, each with its jobs, and the payments that came in, as rows.
  def record_rows(jobs, orders, payments)
    [
      render(partial: "today/job", collection: jobs, as: :job),
      render(partial: "today/order", collection: orders, as: :order),
      render(partial: "today/payment", collection: payments, as: :payment)
    ].compact
  end

  # "4 trabajos · Materiales $8.000", for an order left that day.
  def order_jobs_summary(order)
    return t("today.owed.no_jobs") if order.jobs.empty?

    t("today.order.detail", units: t("today.show.units", count: order.jobs.sum(&:quantity)), materials: pesos(order.jobs.sum(&:materials)))
  end

  # The orders still owed for, each opening its order, and what they come to; nothing while there are none.
  def owed_orders(day)
    render("today/owed", rows: day.pending_orders, total: day.owed) if day.pending_orders.any?
  end

  # The advances, each opening its page; with none yet, what they're for and the way to the first.
  def day_advances(day)
    render(day.advances.any? ? "today/advances" : "today/no_advances", rows: day.advances)
  end

  # What an order still owes. Only an order without jobs yet owes nothing and is still pending, so it says so.
  def owed_amount(row)
    return tag.span(t("today.owed.no_jobs"), class: "text-meta text-graphite") if row.owed.zero?

    tag.span(pesos(row.owed), class: "font-mono text-lg font-bold")
  end
end
