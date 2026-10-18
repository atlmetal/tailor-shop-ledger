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

  # Today's jobs, each opening its form; a line saying there are none yet otherwise.
  def today_jobs(jobs)
    return tag.p(t("today.show.no_jobs"), class: "mt-2.5 text-note text-graphite") if jobs.empty?

    tag.div(render(partial: "today/job", collection: jobs, as: :job), class: "panel mt-2.5 divide-y divide-divider")
  end
end
