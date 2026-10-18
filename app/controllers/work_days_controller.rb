# The shop's work days, set from the fixed costs page. Each day's button sends the work days as they'd be with
# that day flipped, so what the shop sees is always what it saves.
class WorkDaysController < ApplicationController
  def update
    shop = current_tenant

    if shop.update(params.expect(shop: [ work_days: [] ]))
      redirect_to fixed_costs_path
    else
      @month = FixedCosts::MonthFacade.new(shop:)
      render "fixed_costs/index", status: :unprocessable_content
    end
  end
end
