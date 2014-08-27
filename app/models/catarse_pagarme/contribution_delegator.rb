module CatarsePagarme
  class ContributionDelegator
    attr_accessor :contribution

    def initialize(contribution)
      self.contribution = contribution
    end

    def change_status_by_transaction(transactin_status)
      case transactin_status
      when 'paid', 'authorized' then
        self.contribution.confirm unless self.contribution.confirmed?
      when 'refunded' then
        self.contribution.refund unless self.contribution.refunded?
      when 'refused' then
        self.contribution.cancel unless self.contribution.canceled?
      when 'waiting_payment', 'processing' then
        self.contribution.waiting unless self.contribution.waiting_confirmation?
      end
    end

    def value_for_transaction
      (self.contribution.value * 100).to_i
    end

    def get_installments
      PagarMe::Transaction.calculate_installments({
        amount: self.value_for_transaction,
        interest_rate: CatarsePagarme.configuration.interest_rate
      })
    end

    def get_fee(payment_method)
      if payment_method == PaymentType::SLIP
        CatarsePagarme.configuration.slip_tax
      else
        (self.contribution.value * CatarsePagarme.configuration.credit_card_tax) + 0.39
      end
    end
  end
end
