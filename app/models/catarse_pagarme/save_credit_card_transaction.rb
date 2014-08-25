module CatarsePagarme
  class SaveCreditCardTransaction < TransactionBase
    def charge!
      installments = self.attributes.delete(:installments)
      amount = self.attributes.delete(:amount)

      self.subscription = PagarMe::Subscription.new(self.attributes)
      self.subscription.create

      self.subscription.charge(amount, installments)
      self.transaction = subscription.current_transaction

      save_user_credit_card
      change_contribution_state


      self.transaction
    end

    protected

    def save_user_credit_card
      credit_cards = self.user.credit_cards
      unless credit_cards.where(subscription_id: self.subscription.id.to_s).present?
        credit_cards.create!({
          last_digits: self.subscription.card_last_digits,
          card_brand: self.subscription.card_brand,
          subscription_id: self.subscription.id
        })
      end
    end
  end
end
