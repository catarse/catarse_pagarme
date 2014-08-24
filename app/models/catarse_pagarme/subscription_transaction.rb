module CatarsePagarme
  class SubscriptionTransaction
    attr_accessor :attributes, :contribution,
      :transaction, :user, :subscription

    def initialize(attributes, contribution)
      self.attributes = attributes
      self.contribution = contribution
      self.user = contribution.user
    end

    def charge!
      installments = self.attributes.delete(:installments)
      amount = self.attributes.delete(:amount)
      subscription_id = self.attributes.delete(:subscription_id)

      self.subscription = PagarMe::Subscription.find_by_id(subscription_id)
      self.subscription.charge(amount, installments)

      self.transaction = subscription.current_transaction

      contribution_attrs = {
        payment_choice: PaymentType::CREDIT_CARD, 
        payment_service_fee: delegator.get_fee(PaymentType::CREDIT_CARD),
        payment_id: self.transaction.id,
        payment_method: 'Pagarme'
      }
      self.contribution.update_attributes(contribution_attrs)

      delegator.change_status_by_transaction(self.transaction.status)


      self.transaction
    end

    protected

    def delegator
      self.contribution.pagarme_delegator
    end

  end
end
