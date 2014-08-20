module CatarsePagarme
  class PagarmeController < CatarsePagarme::ApplicationController
    include ActionView::Helpers::NumberHelper

    skip_before_filter :force_http
    layout :false
    helper_method :installments_for_select

    def review
      contribution
      current_user.build_bank_account unless current_user.bank_account
    end

    def pay_credit_card
      month, year = params[:payment_card_date].split('/') rescue [0, 0]

      transaction_attrs = {
        payment_method: 'credit_card',
        card_number: params[:payment_card_number],
        card_holder_name: params[:payment_card_name],
        card_expiration_month: month,
        card_expiration_year: year,
        card_cvv: params[:payment_card_source],
        amount: delegator.value_for_transaction,
        postback_url: ipn_pagarme_url(contribution),
      }

      if contribution.value >= 100 && params[:payment_card_installments].present?
        transaction_attrs.merge!({ installments: params[:payment_card_installments]})
      else
        transaction_attrs.merge!({ installments: 1 })
      end

      transaction = charge_transaction(transaction_attrs)
      render json: { payment_status: transaction.status }
    rescue Exception => e
      render json: { payment_status: 'failed', message: e.message }
    end

    def pay_slip
      slip_attrs = {
        slip_payment: {
          payment_method: 'boleto',
          amount: delegator.value_for_transaction,
          postback_url: ipn_pagarme_url(contribution)
        }
      }.merge!(params[:user])

      transaction = SlipTransaction.new(slip_attrs, contribution)
      transaction.charge!

      render json: { boleto_url: transaction.boleto_url, payment_status: transaction.status }
    rescue PagarMe::PagarMeError => e
      render json: { boleto_url: nil, payment_status: 'failed', message: e.message }
    end

    def ipn
      validate_fingerprint do
        if contribution
          contribution.payment_notificatons.create(extra_data: params)
          delegator.change_status_by_transaction(params[:current_status])

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
                                    payment_service_fee: delegator.get_fee(PaymentType::SLIP),
                                  }
                                when 'credit_card' then
                                  {
                                    payment_choice: PaymentType::CREDIT_CARD, 
                                    payment_service_fee: delegator.get_fee(PaymentType::CREDIT_CARD) 
                                  }
                                else
                                  {}
                                end

      contribution_attributes.merge!({ payment_id: transaction.id })
      contribution.update_attributes(contribution_attributes)

      delegator.change_status_by_transaction(transaction.status)

      return transaction
    end

    def installments_for_select
      delegator.get_installments['installments'].collect do |installment|
        if installment[0].to_i <= 6
          number = installment[1]['installment']
          amount = installment[1]['installment_amount'] / 100.to_f
          ["#{number}x #{number_to_currency(amount, precision: 2)}", number]
        end
      end.compact
    end

    def contribution
      conditions = {id: params[:id] }

      unless params[:action] == 'ipn'
        conditions.merge!({user_id: current_user.id})
      end

      @contribution ||= PaymentEngines.find_payment(conditions)
    end

    def delegator
      contribution.pagarme_delegator
    end
  end
end
