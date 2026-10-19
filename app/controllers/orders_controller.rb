class OrdersController < ApplicationController
  before_action :set_order, only: %i[ edit update destroy ]

  def new
    @order = Order.new(received_on: Date.current)
  end

  # Then its first job.
  def create
    @order = Order.new(order_params)

    if @order.save
      redirect_to new_order_job_path(@order)
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @order = Order.includes(:payments, jobs: :service).find(params[:id])
  end

  def edit
  end

  def update
    if @order.update(order_params)
      redirect_to @order
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Cancelling an order: it leaves the accounts with its jobs and payments, since the deposit went back.
  def destroy
    @order.destroy!
    redirect_to root_path
  end

  private
    def set_order
      @order = Order.find(params[:id])
    end

    def order_params
      params.expect(order: %i[ customer_name received_on ])
    end
end
