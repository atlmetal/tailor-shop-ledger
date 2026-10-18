class FixedCostsController < ApplicationController
  def index
    @month = FixedCosts::MonthFacade.new(shop: current_tenant)
  end

  def create
    new_fixed_cost = NewFixedCost.new(new_fixed_cost_params.merge(shop: current_tenant))

    if FixedCosts::CreateService.call(form: new_fixed_cost)
      redirect_to fixed_costs_path
    else
      @month = FixedCosts::MonthFacade.new(shop: current_tenant, new_fixed_cost:)
      render :index, status: :unprocessable_content
    end
  end

  def update
    change = FixedCostChange.new(change_params.merge(fixed_cost: FixedCost.find(params[:id])))

    if FixedCosts::ChangeService.call(change:)
      redirect_to fixed_costs_path
    else
      @month = FixedCosts::MonthFacade.new(shop: current_tenant, change:)
      render :index, status: :unprocessable_content
    end
  end

  private
    def new_fixed_cost_params
      params.expect(new_fixed_cost: %i[ name averaged amount starts_on ])
    end

    def change_params
      params.expect(fixed_cost_change: %i[ amount starts_on remove ])
    end
end
