module OrdersHelper
  # "Lo dejó el martes 15 de octubre".
  def order_received_on(order)
    t("orders.show.received_on", day: l(order.received_on, format: :day))
  end

  # "Pedido de Marta Rodríguez", back to the order.
  def order_link(order)
    link_to t("orders.order", customer: order.customer_name), order_path(order), class: "btn-link text-note"
  end

  # What the customer still owes and has paid, or that the order is paid off; nothing while it has no jobs.
  def order_summary(order)
    return if order.jobs.empty?

    render(order.owed.positive? ? "orders/owed" : "orders/paid_off", order:)
  end

  # While the customer owes something.
  def record_payment_button(order)
    link_to t("orders.show.record_payment"), new_order_payment_path(order), class: "btn-primary mt-5" if order.owed.positive?
  end

  # "4 trabajos", counting each job's units; nothing while there are none.
  def order_units(order)
    t("today.show.units", count: order.jobs.sum(&:quantity)) if order.jobs.any?
  end

  # Adding a job is the next step while the order has none, and an extra one after.
  def add_job_class(order)
    token_list("mt-3 gap-2", order.jobs.empty? ? "btn-primary" : "btn-secondary")
  end

  # Each job opening its form, or a line saying there are none yet.
  def order_jobs(order)
    return tag.p(t("orders.show.no_jobs"), class: "mt-2.5 text-note text-graphite") if order.jobs.empty?

    tag.div(render(partial: "today/job", collection: order.jobs, as: :job), class: "panel mt-2.5 divide-y divide-divider")
  end

  # Each payment opening its form, or a line saying there are none yet.
  def order_payments(order)
    return tag.p(t("orders.show.no_payments"), class: "mt-2.5 text-note text-graphite") if order.payments.empty?

    tag.div(render(partial: "orders/payment", collection: order.payments, as: :payment), class: "panel mt-2.5 divide-y divide-divider")
  end

  # What's owed for a new payment; for one already recorded, what's owed leaving it out.
  def payment_owed_hint(payment)
    t(payment.new_record? ? "orders.payments.form.owed" : "orders.payments.form.owed_without", amount: pesos(payment.owed))
  end
end
