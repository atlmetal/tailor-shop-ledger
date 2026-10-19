module JobsHelper
  # "Guardado: 2 × Basta de pantalón, $16.000. Sigue con el próximo.", after "Guardar y registrar otro".
  def job_saved_notice
    render("jobs/saved", job: flash[:saved]) if flash[:saved]
  end

  # A job in an order is changed under the order.
  def edit_job_path_for(job)
    job.order ? edit_order_job_path(job.order, job) : edit_job_path(job)
  end

  # A job in an order is saved under the order.
  def job_form_model(job)
    job.order ? [ job.order, job ] : job
  end

  # The date of a job on its own; one in an order takes the order's day.
  def job_date_field(form, job)
    render("jobs/date", form:, job:) unless job.order
  end

  # The form's question and price hint, which for a job in an order speak of work still to do.
  def job_form_text(job, key)
    t(job.order ? "jobs.form.order_#{key}" : "jobs.form.#{key}")
  end
end
