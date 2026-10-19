module Orders
  # An order's payments. Everything goes back to the order's page.
  class PaymentsController < ApplicationController
    before_action :set_order
    before_action :set_payment, only: %i[ edit update destroy ]

    # The first payment, usually the deposit, starts empty; a later one, with what's still owed.
    def new
      @payment = @order.payments.new(paid_on: Date.current, amount: (@order.owed if @order.payments.exists?))
    end

    def create
      @payment = @order.payments.new(payment_params)

      if @payment.save
        redirect_to @order
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @payment.update(payment_params)
        redirect_to @order
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @payment.destroy!
      redirect_to @order
    end

    private
      def set_order
        @order = Order.find(params[:order_id])
      end

      def set_payment
        @payment = @order.payments.find(params[:id])
      end

      def payment_params
        params.expect(payment: %i[ paid_on amount ])
      end
  end
end
