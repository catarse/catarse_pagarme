module CatarsePagarme
  class CreditCardTransaction
    attr_accessor :attributes, :contribution

    def initialize(attributes, contribution)
      self.attributes = attributes
      self.contribution = contribution
    end

    def charge!
      transaction = PagarMe::Transaction.new(self.attributes)
      transaction.charge

      contribution_attrs = {
        payment_choice: PaymentType::CREDIT_CARD, 
        payment_service_fee: delegator.get_fee(PaymentType::CREDIT_CARD),
        payment_id: transaction.id,
        payment_method: 'Pagarme'
      }
      contribution.update_attributes(contribution_attrs)

      delegator.change_status_by_transaction(transaction.status)

      transaction
    end

    protected

    def delegator
      self.contribution.pagarme_delegator
    end
  end
end
