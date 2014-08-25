module CatarsePagarme
  class PagarmeController < CatarsePagarme::ApplicationController

    before_filter :authenticate_user!, except: [:review]
    skip_before_filter :force_http
    layout :false

    def review
      contribution
      current_user.build_bank_account unless current_user.bank_account
    end

    def pay_with_subscription
      transaction_attrs = build_default_credit_card_hash

      if has_subscription?
        transaction = SubscriptionTransaction.new(transaction_attrs, contribution).charge!
      else
        transaction = SaveCreditCardTransaction.new(transaction_attrs, contribution).charge!
      end

      render json: { payment_status: transaction.status }
    rescue Exception => e
      render json: { payment_status: 'failed', message: e.message }
    end

    def pay_credit_card
      transaction_attrs = build_default_credit_card_hash

      if contribution.value < CatarsePagarme.configuration.minimum_value_for_installment
        transaction_attrs.update({ installments: 1 })
      end

      transaction = CreditCardTransaction.new(transaction_attrs, contribution).charge!

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
      }.merge!({ user: params[:user] })

      transaction = SlipTransaction.new(permited_attrs(slip_attrs), contribution).charge!

      render json: { boleto_url: transaction.boleto_url, payment_status: transaction.status }
    rescue PagarMe::PagarMeError => e
      render json: { boleto_url: nil, payment_status: 'failed', message: e.message }
    end

    def ipn
      if PagarMe::validate_fingerprint(params[:id], params[:fingerprint])
        if contribution
          contribution.payment_notificatons.create(extra_data: params)
          delegator.change_status_by_transaction(params[:current_status])

          return render nothing: { status: 200 }
        end

        return render nothing: { status: 404 }
      end
    end

    protected

    def build_default_credit_card_hash
      if has_subscription?
        {
          subscription_id: params[:subscription_id],
          postback_url: ipn_pagarme_url(contribution),
          installments: params[:payment_card_installments],
          amount: delegator.value_for_transaction
        }
      else
        {
          payment_method: 'credit_card',
          card_number: params[:payment_card_number],
          card_holder_name: params[:payment_card_name],
          card_expiration_month: splited_month_and_year[0],
          card_expiration_year: splited_month_and_year[1],
          card_cvv: params[:payment_card_source],
          amount: delegator.value_for_transaction,
          postback_url: ipn_pagarme_url(contribution),
          installments: params[:payment_card_installments],
          customer: {
            email: current_user.email
          }
        }
      end
    end

    def has_subscription?
      params[:subscription_id].present?
    end

    def splited_month_and_year
      params[:payment_card_date].split('/')
    rescue
      [0, 0]
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
