module CatarsePagarme
  class Configuration
    attr_accessor :api_key, :slip_tax, :credit_card_tax

    def inititalizer
      @api_key = ''
      @slip_tax = 0
      @credit_card_tax = 0
    end
  end
end
