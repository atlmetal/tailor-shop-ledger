module Advances
  # An advance's jobs: the job form with its date, and the balance each one leaves. Everything goes back to the
  # advance's page.
  class JobsController < ApplicationController
    include JobForm

    before_action :set_advance
    before_action :set_job, only: %i[ edit update destroy ]
    before_action :set_services, only: %i[ new create edit update ]

    # "Guardar y agregar otro" comes back here with the date and the service it keeps.
    def new
      @job = @advance.jobs.new(done_on: params.fetch(:done_on, Date.current), service_id: params[:service_id], quantity: 1)
    end

    def create
      @job = @advance.jobs.new(job_params)

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
        redirect_to @advance
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @job.destroy!
      redirect_to @advance
    end

    private
      def set_advance
        @advance = Advance.find(params[:advance_id])
      end

      def set_job
        @job = @advance.jobs.find(params[:id])
      end

      def job_params
        params.expect(job: %i[ done_on service_id quantity price material_cost ])
      end

      def redirect_after_create
        if params[:another]
          redirect_to new_advance_job_path(@advance, done_on: @job.done_on, service_id: @job.service_id), flash: { saved: saved_notice }
        else
          redirect_to @advance
        end
      end
  end
end
