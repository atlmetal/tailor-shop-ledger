class ServicesController < ApplicationController
  before_action :set_service, only: %i[ edit update ]

  def index
    @services = Service.active.order(:name)
    @inactive_services = Service.inactive.order(:name)
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
