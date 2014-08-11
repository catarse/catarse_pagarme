module CatarsePagarme
  class PagarmeController < CatarsePagarme::ApplicationController

    skip_before_filter :force_http
    layout :false

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

    def ipn
      validate_fingerprint do
        _contribution = PaymentEngines.find_payment(payment_id: params['id'])

        if _contribution
          _contribution.payment_notificatons.create(extra_data: params)

          case params[:current_status]
          when 'paid' && !_contribution.confirmed? then
            _contribution.confirm
          when 'refunded' && !_contribution.refunded? then
            _contribution.refund
          when 'refused' then
            _contribution.cancel
          end

          return render nothing: { status: 200 }
        end

        return render nothing: { status: 404 }
      end
    end

    protected

    def validate_fingerprint
      if PagarMe::validate_fingerprint(params[:id], params[:fingerprint])
        yield
      end
    end

    def charge_transaction(transaction_attributes = {})
      transaction = PagarMe::Transaction.new(transaction_attributes)
      transaction.charge

      contribution_attributes = case transaction_attributes[:payment_method]
                                when 'boleto' then
                                  {
                                    payment_choice: PaymentType::SLIP,
                                    payment_service_fee: get_fee(PaymentType::SLIP),
                                  }
                                when 'credit_card' then
                                  {
                                    payment_choice: PaymentType::CREDIT_CARD, 
                                    payment_service_fee: get_fee(PaymentType::CREDIT_CARD) 
                                  }
                                else
                                  {}
                                end

      contribution_attributes.merge!({ payment_id: transaction.id })
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
