module CatarsePagarme
  class CreditCardsController < CatarsePagarme::ApplicationController

    def create
      transaction = CreditCardTransaction.new(credit_card_attributes, contribution).charge!

      render json: { payment_status: transaction.status }
    rescue Exception => e
      render json: { payment_status: 'failed', message: e.message }
    end

    protected

    def credit_card_attributes
      hash = {
        payment_method: 'credit_card',
        amount: delegator.value_with_installment_tax(get_installment),
        postback_url: ipn_pagarme_index_url(host: CatarsePagarme.configuration.host,
                                            subdomain: CatarsePagarme.configuration.subdomain,
                                            protocol: CatarsePagarme.configuration.protocol),
        installments: get_installment,
        customer: {
          email: contribution.user.email,
          name: contribution.user.name
        },
        metadata: {
          key: contribution.key
        }
      }

      if params[:card_hash].present?
        hash[:card_hash] = params[:card_hash]
      else
        hash[:card_id] = params[:card_id]
      end

      if params[:save_card] === "true"
        hash[:save_card] = true
      end

      hash
    end

    def get_installment
      if contribution.value.to_f < CatarsePagarme.configuration.minimum_value_for_installment.to_f
        1
      elsif params[:payment_card_installments].to_i > 0
        params[:payment_card_installments].to_i
      else
        1
      end
    end

  end
end
