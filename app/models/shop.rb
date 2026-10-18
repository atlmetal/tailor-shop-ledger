class Shop < ApplicationRecord
  # Weekdays as Date#wday numbers, 0 for Sunday.
  normalizes :work_days, with: ->(days) { days.compact.uniq.sort }

  validates :name, :started_on, presence: true
  validates :work_days, presence: true
  validate -> { errors.add(:work_days, :inclusion) unless work_days.all?(0..6) }

  # How many of the dates fall on the shop's work days.
  def work_days_in(dates)
    dates.count { work_days.include?(it.wday) }
  end
end
