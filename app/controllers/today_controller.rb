class TodayController < ApplicationController
  def show
    @day = Today::DayFacade.new(shop: current_tenant)
  end
end
