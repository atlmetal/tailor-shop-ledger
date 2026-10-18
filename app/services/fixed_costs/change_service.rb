module FixedCosts
  # Sets a fixed cost's amount from a month on, and earlier months keep theirs. A month that already has a
  # change gets this one instead, so a typo can be fixed within the month. Leaves the form's errors on it.
  class ChangeService < ApplicationService
    def initialize(change:)
      @change = change
    end

    def call
      return false unless @change.valid?

      @change.fixed_cost.amounts.find_or_initialize_by(starts_on: @change.starts_on).update!(amount: @change.amount)
    end
  end
end
