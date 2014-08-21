class Contribution < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  def confirmed?
    false
  end

  def update_current_billing_info
  end

  def confirm!
    true
  end
end
