module CatarsePagarme
  class SubscriptionsController < CreditCardBaseController
    def create
      charge_with_class SaveCreditCardTransaction
    end

    def update
      charge_with_class SubscriptionTransaction
    end

    protected

    def credit_card_attributes
      attributes = super

      if has_subscription?
        attributes.update({subscription_id: params[:subscription_id]})
      end

      attributes
    end

    def has_subscription?
      params[:subscription_id].present?
    end
  end
end
