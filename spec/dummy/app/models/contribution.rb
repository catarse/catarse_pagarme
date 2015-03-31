class Contribution < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  has_many :payment_notifications
  has_many :payments
end
