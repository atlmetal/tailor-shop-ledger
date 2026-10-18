class Shop < ApplicationRecord
  validates :name, :started_on, presence: true

  # How many of the dates fall on the shop's work days.
  def work_days_in(dates)
    dates.count { work_days.include?(it.wday) }
  end
end
