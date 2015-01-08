module CatarsePagarme
  class Configuration
    attr_accessor :api_key, :slip_tax, :credit_card_tax, :interest_rate, :host, :subdomain, :protocol,
      :max_installments, :minimum_value_for_installment, :credit_card_cents_fee, :pagarme_tax, :stone_tax,
      :cielo_tax, :cielo_installment_diners_tax, :cielo_installment_not_diners_tax,
      :cielo_installment_amex_tax, :cielo_installment_not_amex_tax

    def initialize
      self.api_key = ''
      self.slip_tax = 0
      self.credit_card_tax = 0
      self.interest_rate = 0
      self.max_installments = 12
      self.minimum_value_for_installment = 10
      self.credit_card_cents_fee = 0.39
      self.host = 'catarse.me'
      self.subdomain = 'www'
      self.protocol = 'http'
      self.pagarme_tax = 0.0063
      self.stone_tax = 0.0307
      self.cielo_tax = 0.038
      self.cielo_installment_diners_tax = 0.048
      self.cielo_installment_not_diners_tax = 0.0455
    end
  end
end
