# Jobs on their own, paid when they're done. An order's jobs go through Orders::JobsController.
class JobsController < ApplicationController
  include JobForm

  before_action :set_job, only: %i[ edit update destroy ]
  before_action :set_services, only: %i[ new create edit update ]

  # "Guardar y registrar otro" comes back here with the date and the service it keeps.
  def new
    @job = Job.new(done_on: params.fetch(:done_on, Date.current), service_id: params[:service_id], quantity: 1)
  end

  def create
    @job = Job.new(job_params)

    if @job.save
      redirect_after_create
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @job.update(job_params)
      redirect_to record_return_path(@job.done_on)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @job.destroy!
    redirect_to record_return_path(@job.done_on)
  end

  private
    def set_job
      @job = Job.where(order: nil).find(params[:id])
    end

    def job_params
      params.expect(job: %i[ done_on service_id quantity price material_cost ])
    end

    def redirect_after_create
      if params[:another]
        redirect_to new_job_path(done_on: @job.done_on, service_id: @job.service_id), flash: { saved: saved_notice }
      else
        redirect_to record_return_path(@job.done_on)
      end
    end
end
