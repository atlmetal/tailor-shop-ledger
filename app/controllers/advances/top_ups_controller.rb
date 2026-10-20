module Advances
  # An advance's top-ups. Everything goes back to the advance's page.
  class TopUpsController < ApplicationController
    before_action :set_advance
    before_action :set_top_up, only: %i[ edit update destroy ]

    def new
      @top_up = @advance.top_ups.new(paid_on: Date.current)
    end

    def create
      @top_up = @advance.top_ups.new(top_up_params)

      if @top_up.save
        redirect_to @advance
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @top_up.update(top_up_params)
        redirect_to @advance
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @top_up.destroy!
      redirect_to @advance
    end

    private
      def set_advance
        @advance = Advance.find(params[:advance_id])
      end

      def set_top_up
        @top_up = @advance.top_ups.find(params[:id])
      end

      def top_up_params
        params.expect(top_up: %i[ paid_on amount ])
      end
  end
end
