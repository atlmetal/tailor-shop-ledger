class Shop < ApplicationRecord
  validates :name, :started_on, presence: true
end
