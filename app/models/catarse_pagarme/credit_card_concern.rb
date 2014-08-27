module CatarsePagarme::CreditCardConcern
  extend ActiveSupport::Concern

  included do
    def pagarme_delegator
      CatarsePagarme::CreditCardDelegator.new(self)
    end
  end
end
