class PaymentEngines
  def self.new_payment(attributes={})
    Payment.new attributes
  end

  def self.find_contribution(id)
    Contribution.find id
  end
end
