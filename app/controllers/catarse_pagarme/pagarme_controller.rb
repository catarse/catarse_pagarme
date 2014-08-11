module CatarsePagarme
  class PagarmeController < CatarsePagarme::ApplicationController

    skip_before_filter :force_http
    layout :false

    def ipn
    end

    def pay_credit_card
      transaction = charge_transaction {}
    end

    def pay_slip
      transaction = charge_transaction({
        payment_method: 'boleto',
        amount: (contribution.value * 100).to_i,
        postback_url: ipn_pagarme_index_url
      })

      render json: { boleto_url: transaction.boleto_url, payment_status: transaction.status }
    rescue PagarMe::PagarMeError => e
      render json: { boleto_url: nil, payment_status: 'failed', message: e.message }
    end
    end

    protected

    def charge_transaction(transaction_attributes = {})
      transaction = PagarMe::Transaction.new(transaction_attributes)
      transaction.charge

      contribution_attributes = case transaction_attributes[:payment_method]
                                when 'boleto' then
                                  {
                                    payment_choice: PaymentType::SLIP,
                                    payment_service_fee: get_fee(PaymentType::SLIP) 
                                  }
                                when 'credit_card' then
                                  {
                                    payment_choice: PaymentType::CREDIT_CARD, 
                                    payment_service_fee: get_fee(PaymentType::CREDIT_CARD) 
                                  }
                                else
                                  {}
                                end

      contribution.update_attributes(contribution_attributes)

      return transaction
    end

    def contribution
      @contribution ||= PaymentEngines.find_payment(id: params['id'], user_id: current_user.id)
    end

    def get_fee(payment_method)
      if payment_method == PaymentType::SLIP
        CatarsePagarme.configuration.slip_tax
      else
        0
      end
    end

  end
end
