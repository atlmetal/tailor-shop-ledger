module Orders
  # An order's jobs: the job form without a date, since they take the order's day. Everything goes back to the
  # order's page.
  class JobsController < ApplicationController
    include JobForm

    before_action :set_order
    before_action :set_job, only: %i[ edit update destroy ]
    before_action :set_services, only: %i[ new create edit update destroy ]

    # "Guardar y agregar otro" comes back here with the service it keeps.
    def new
      @job = @order.jobs.new(service_id: params[:service_id], quantity: 1)
    end

    def create
      @job = @order.jobs.new(job_params)

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
        redirect_to @order
      else
        render :edit, status: :unprocessable_content
      end
    end

    # Not while the order's other jobs don't cover what the customer has paid.
    def destroy
      if @job.destroy
        redirect_to @order
      else
        render :edit, status: :unprocessable_content
      end
    end

    private
      def set_order
        @order = Order.find(params[:order_id])
      end

      def set_job
        @job = @order.jobs.find(params[:id])
      end

      def job_params
        params.expect(job: %i[ service_id quantity price material_cost ])
      end

      def redirect_after_create
        if params[:another]
          redirect_to new_order_job_path(@order, service_id: @job.service_id), flash: { saved: saved_notice }
        else
          redirect_to @order
        end
      end
  end
end
