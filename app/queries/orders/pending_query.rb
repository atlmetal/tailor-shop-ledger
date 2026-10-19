module Orders
  # The orders customers still owe for, the oldest first, each with what's owed: those whose payments don't cover
  # their jobs yet, and those with no jobs yet.
  class PendingQuery < ApplicationQuery
    Row = Data.define(:order, :owed)

    def call
      total = coalesce(Job.where(Job[:order_id].eq(Order[:id])).select((Job[:quantity] * Job[:price]).sum))
      paid = coalesce(Payment.where(Payment[:order_id].eq(Order[:id])).select(Payment[:amount].sum))
      no_jobs = Job.where(Job[:order_id].eq(Order[:id])).arel.exists.not

      Order.where(paid.lt(total).or(no_jobs)).select(Order[Arel.star], (total - paid).as("owed")).order(:received_on, :id)
        .map { Row.new(order: it, owed: it[:owed]) }
    end

    private
      # What a correlated subquery sums for each order, 0 when it has nothing to sum.
      def coalesce(relation)
        Arel::Nodes::NamedFunction.new("COALESCE", [ relation.arel, Arel::Nodes.build_quoted(0) ])
      end
  end
end
