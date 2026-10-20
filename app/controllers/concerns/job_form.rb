# What the job form needs, for jobs on their own, in an order and in an advance: the services to choose from, and
# the notice after "Guardar y registrar otro".
module JobForm
  extend ActiveSupport::Concern

  private
    # The active services, and the one the job has when it was deactivated after.
    def set_services
      @services = Service.active.or(Service.where(id: @job&.service_id)).order(:id)
    end

    # "2 × Basta de pantalón, $16.000", which the form shows after "Guardado:".
    def saved_notice
      t("jobs.create.saved", quantity: @job.quantity, service: @job.service.name, charged: helpers.pesos(@job.charged))
    end
end
