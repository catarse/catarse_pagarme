module CatarsePagarme
  class SubscriptionTransaction < TransactionBase
    def charge!
      self.subscription = PagarMe::Subscription.find_by_id(self.attributes[:subscription_id])
      self.subscription.charge(self.attributes[:amount], self.attributes[:installments])
      self.transaction = subscription.current_transaction

      change_contribution_state

      self.transaction
    end
  end
end
