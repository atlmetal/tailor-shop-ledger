module ServicesHelper
  # "Te deja $7.500", in the loss color when the materials cost more than the price.
  def service_leaves(service)
    t("services.service.leaves_html", amount: tag.strong(pesos(service.leaves), class: token_list("font-mono", "text-loss-ink": service.leaves.negative?)))
  end

  # The deactivated services, folded under their count; nothing when there are none.
  def inactive_services(services)
    render("services/inactive", services:) if services.present?
  end
end
