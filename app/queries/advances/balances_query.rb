module Advances
  # The shop's advances by the customer's name, each with its balance: what its top-ups add up to minus what its
  # jobs charge, below 0 when the customer owes.
  class BalancesQuery < ApplicationQuery
    Row = Data.define(:advance, :balance)

    def call
      given = coalesce(TopUp.where(TopUp[:advance_id].eq(Advance[:id])).select(TopUp[:amount].sum))
      charged = coalesce(Job.where(Job[:advance_id].eq(Advance[:id])).select((Job[:quantity] * Job[:price]).sum))

      Advance.select(Advance[Arel.star], (given - charged).as("balance")).order(Advance[:customer_name].lower, :id)
        .map { Row.new(advance: it, balance: it[:balance]) }
    end
  end
end
