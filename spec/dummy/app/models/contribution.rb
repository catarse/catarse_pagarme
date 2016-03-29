class Contribution < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :country
  has_many :payment_notifications
  has_many :payments

  def international?
    false
  end
end
