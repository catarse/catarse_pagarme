module CatarsePagarme
  class Configuration
    attr_accessor :api_key, :slip_tax, :credit_card_tax, :interest_rate,
      :max_installments, :minimum_value_for_installment

    def initialize
      self.api_key = ''
      self.slip_tax = 0
      self.credit_card_tax = 0
      self.interest_rate = 0
      self.max_installments = 6
      self.minimum_value_for_installment = 100
    end
  end
end
