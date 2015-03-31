class Payment < ActiveRecord::Base
  has_many :payment_notifications
  belongs_to :contribution
  delegate :user, :project, to: :contribution

  validates_presence_of :state, :key, :gateway, :payment_method, :value, :installments, :installment_value
  validate :value_should_be_equal_or_greater_than_pledge

  before_validation do
    self.key ||= SecureRandom.uuid
    self.value ||= self.contribution.try(:value)
    self.state = 'pending' # mock initial state for here we do not include the stat machine
  end

  def value_should_be_equal_or_greater_than_pledge
    errors.add(:value, I18n.t("activerecord.errors.models.payment.attributes.value.invalid")) if self.contribution && self.value < self.contribution.value
  end

  def notification_template_for_failed_project
    if slip_payment?
      :contribution_project_unsuccessful_slip
    else
      :contribution_project_unsuccessful_credit_card
    end
  end

  def refunded?
    true
  end

  def paid?
    true
  end

  def refused?
    true
  end

  def refuse
  end

  def pay
  end

  def refund
  end

  def credits?
    self.gateway == 'Credits'
  end

  def slip_payment?
    self.payment_method == 'BoletoBancario'
  end
end
