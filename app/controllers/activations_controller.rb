# A service is deactivated rather than deleted, so its jobs keep it, and can be activated again.
class ActivationsController < ApplicationController
  before_action :set_service

  def create
    if @service.update(active: true)
      redirect_to services_path, notice: t(".activated", name: @service.name)
    else
      # Its name is all that can clash: an active service already has it.
      redirect_to services_path, alert: t(".name_taken", name: @service.name)
    end
  end

  def destroy
    @service.update!(active: false)
    redirect_to services_path, notice: t(".deactivated", name: @service.name)
  end

  private
    def set_service
      @service = Service.find(params[:service_id])
    end
end
