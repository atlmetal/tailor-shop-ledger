class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Arel column shorthand: Job[:done_on].
  def self.[](column)
    arel_table[column]
  end
end
