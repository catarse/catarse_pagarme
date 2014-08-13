module CatarsePagarme
  class Configuration
    attr_accessor :api_key, :slip_tax, :credit_card_tax, :interest_rate

    def inititalizer
      self.api_key = ''
      self.slip_tax = 0
      self.credit_card_tax = 0
      self.interest_rate = 0
    end
  end
end
