module JobsHelper
  # "Guardado: 2 × Basta de pantalón, $16.000. Sigue con el próximo.", after "Guardar y registrar otro".
  def job_saved_notice
    render("jobs/saved", job: flash[:saved]) if flash[:saved]
  end

  # A job in an order or an advance is changed under it.
  def edit_job_path_for(job)
    if job.order then edit_order_job_path(job.order, job)
    elsif job.advance then edit_advance_job_path(job.advance, job)
    else edit_job_path(job)
    end
  end

  # "Adelanto de Hotel Almendros", under a job in an advance among the day's records.
  def job_advance(job)
    tag.span(t("advances.advance", customer: job.advance.customer_name), class: "text-meta text-graphite") if job.advance
  end

  # A job in an order or an advance is saved under it.
  def job_form_model(job)
    parent = job.order || job.advance
    parent ? [ parent, job ] : job
  end

  # The date of a job on its own; one in an order takes the order's day.
  def job_date_field(form, job)
    render("jobs/date", form:, job:) unless job.order
  end

  # The form's question and price hint, which for a job in an order speak of work still to do, and in an advance
  # of work for the customer.
  def job_form_text(job, key)
    prefix = if job.order then "order_" elsif job.advance then "advance_" end
    t("jobs.form.#{prefix}#{key}")
  end

  # In an advance, the balance the job leaves or, past it, what the customer would owe, which the form keeps up to
  # date while the user types.
  def job_balance(job)
    return unless job.advance

    balance = job.advance_balance
    left = balance - job.charged
    render("jobs/balance", job:, balance:, left:, owes: left.negative?)
  end
end
