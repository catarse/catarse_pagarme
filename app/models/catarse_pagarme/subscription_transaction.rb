module CatarsePagarme
  class SubscriptionTransaction < TransactionBase
    def charge!
      validate_subscription_id

      self.subscription = PagarMe::Subscription.find_by_id(self.attributes[:subscription_id])
      self.subscription.charge(self.attributes[:amount], self.attributes[:installments])
      self.transaction = subscription.current_transaction

      change_contribution_state

      self.transaction
    end

    def validate_subscription_id
      unless self.user.credit_cards.where(subscription_id: self.attributes[:subscription_id]).present?
        raise PagarMe::PagarMeError.new('invalid subscription')
      end
    end
  end
end
