module CatarsePagarme
  class CreditCardsController < CreditCardBaseController

    def create
      charge_with_class CreditCardTransaction
    end
  end
end
