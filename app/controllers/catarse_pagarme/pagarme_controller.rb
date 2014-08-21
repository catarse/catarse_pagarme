module CatarsePagarme
  class PagarmeController < CatarsePagarme::ApplicationController
    include ActionView::Helpers::NumberHelper

    before_filter :authenticate_user!, except: [:review]
    skip_before_filter :force_http
    layout :false
    helper_method :installments_for_select

    def review
      contribution
      current_user.build_bank_account unless current_user.bank_account
    end

    def pay_credit_card
      month, year = get_splited_month_and_year

      transaction_attrs = {
        payment_method: 'credit_card',
        card_number: params[:payment_card_number],
        card_holder_name: params[:payment_card_name],
        card_expiration_month: month,
        card_expiration_year: year,
        card_cvv: params[:payment_card_source],
        amount: delegator.value_for_transaction,
        postback_url: ipn_pagarme_url(contribution),
        installments: params[:payment_card_installments]
      }

      if contribution.value < 100
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

    def get_splited_month_and_year
      params[:payment_card_date].split('/')
    rescue
      [0, 0]
    end

    def validate_fingerprint
      if PagarMe::validate_fingerprint(params[:id], params[:fingerprint])
        yield
      end
    end

    # TODO: Move this for helper file
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
