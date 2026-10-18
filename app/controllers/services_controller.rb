class ServicesController < ApplicationController
  before_action :set_service, only: %i[ edit update ]

  # In the order they were added, so a shop can put the services it does most first.
  def index
    @services = Service.active.order(:id)
    @inactive_services = Service.inactive.order(:id)
  end

  def new
    @service = Service.new
  end

  def create
    @service = Service.new(service_params)

    if @service.save
      redirect_to services_path, notice: t(".saved", name: @service.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @service.update(service_params)
      redirect_to services_path, notice: t(".saved", name: @service.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_service
      @service = Service.find(params[:id])
    end

    def service_params
      params.expect(service: %i[ name price material_cost ])
    end
end
