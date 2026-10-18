class JobsController < ApplicationController
  before_action :set_services, only: %i[ new create ]

  # "Guardar y registrar otro" comes back here with the date and the service it keeps.
  def new
    @job = Job.new(done_on: params.fetch(:done_on, Date.current), service_id: params[:service_id], quantity: 1)
  end

  def create
    @job = Job.new(job_params)

    if @job.save
      redirect_after_save
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def set_services
      @services = Service.active.order(:id)
    end

    def job_params
      params.expect(job: %i[ done_on service_id quantity price material_cost ])
    end

    # Every job returns to Today until the day's report exists (M7).
    def redirect_after_save
      if params[:another]
        saved = t(".saved", quantity: @job.quantity, service: @job.service.name, charged: helpers.pesos(@job.charged))
        redirect_to new_job_path(done_on: @job.done_on, service_id: @job.service_id), flash: { saved: }
      else
        redirect_to root_path
      end
    end
end
