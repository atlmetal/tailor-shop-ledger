module FixedCosts
  # Adds a fixed cost with its first monthly amount, both or neither. Leaves the form's errors on it.
  class CreateService < ApplicationService
    def initialize(form:)
      @form = form
    end

    def call
      return false unless @form.valid?

      FixedCost.transaction do
        fixed_cost = FixedCost.create!(name: @form.name, averaged: @form.averaged)
        fixed_cost.amounts.create!(starts_on: @form.starts_on, amount: @form.amount)
        fixed_cost
      end
    end
  end
end
