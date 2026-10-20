module AdvancesHelper
  # "Le quedan" while something is left, or nothing; "Te debe" past it.
  def balance_word(balance)
    t(balance.negative? ? "advances.balance.owes" : "advances.balance.left")
  end

  # "Adelanto desde el 1 de octubre"; nothing while it has no top-ups or jobs.
  def advance_since(advance)
    since = advance.since
    t("advances.show.since", day: l(since, format: :day_month)) if since
  end

  # "Adelanto de Hotel Almendros", back to the advance.
  def advance_link(advance)
    link_to t("advances.advance", customer: advance.customer_name), advance_path(advance), class: "btn-link text-note"
  end

  # What's left of the advance or what the customer owes, and how it comes about.
  def advance_summary(advance)
    render("advances/summary", advance:, balance: advance.balance)
  end

  # "29 trabajos", counting each job's units; nothing while there are none.
  def advance_units(advance)
    t("today.show.units", count: advance.jobs.sum(&:quantity)) if advance.jobs.any?
  end

  # Each job, the most recent first, opening its form, or a line saying there are none yet.
  def advance_jobs(advance)
    return tag.p(t("advances.show.no_jobs"), class: "mt-2.5 text-note text-graphite") if advance.jobs.empty?

    tag.div(render(partial: "advances/job", collection: advance.jobs, as: :job), class: "panel mt-2.5 divide-y divide-divider")
  end

  # Each top-up, the most recent first, opening its form, or a line saying there are none yet.
  def advance_top_ups(advance)
    return tag.p(t("advances.show.no_top_ups"), class: "mt-2.5 text-note text-graphite") if advance.top_ups.empty?

    tag.div(render(partial: "advances/top_up", collection: advance.top_ups, as: :top_up), class: "panel mt-2.5 divide-y divide-divider")
  end

  # What the advance has left, or what the customer owes; for a top-up already recorded, leaving it out.
  def top_up_balance_hint(top_up)
    balance = top_up.advance_balance
    key = balance.negative? ? "owes" : "left"
    t("advances.top_ups.form.#{key}#{"_without" if top_up.persisted?}", amount: pesos(balance.abs))
  end

  # Deleting it, only while it has no jobs, since they counted.
  def delete_advance(advance)
    render("advances/delete", advance:) if advance.jobs.empty?
  end
end
