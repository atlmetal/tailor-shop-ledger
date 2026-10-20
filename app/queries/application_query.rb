class ApplicationQuery
  def self.call(...)
    new(...).call
  end

  private
    # What a correlated subquery sums for each row, 0 when it has nothing to sum.
    def coalesce(relation)
      Arel::Nodes::NamedFunction.new("COALESCE", [ relation.arel, Arel::Nodes.build_quoted(0) ])
    end
end
