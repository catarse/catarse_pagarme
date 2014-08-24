module CatarsePagarme
  class SaveCreditCardTransaction
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

      self.subscription = PagarMe::Subscription.new(self.attributes)
      self.subscription.create

      self.subscription.charge(amount, installments)
      self.transaction = subscription.current_transaction

      save_user_credit_card

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

    def save_user_credit_card
      credit_cards = self.user.credit_cards
      unless credit_cards.where(object_id: self.subscription.id.to_s).present?
        credit_cards.create!({
          last_digits: self.subscription.card_last_digits,
          card_brand: self.subscription.card_brand,
          object_id: self.subscription.id
        })
      end
    end
  end
end
