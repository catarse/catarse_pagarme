module CatarsePagarme
  class CreditCardDelegator
    attr_accessor :credit_card, :subscription

    def initialize(credit_card)
      configure_pagarme
      self.credit_card = credit_card
    end

    def cancel_subscription
      get_subscription
      self.subscription.cancel
    end

    def get_subscription
      self.subscription ||= ::PagarMe::Subscription.find_by_id(self.credit_card.subscription_id)
    end


    protected

    def configure_pagarme
      ::PagarMe.api_key = CatarsePagarme.configuration.api_key
    end
  end
end
