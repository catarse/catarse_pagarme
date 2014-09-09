module CatarsePagarme
  class PagarmeController < CatarsePagarme::ApplicationController

    def review
      contribution
      current_user.build_bank_account unless current_user.bank_account
    end

    def pay_with_subscription
      transaction_attrs = build_default_credit_card_hash

      kclass = (has_subscription? ? SubscriptionTransaction : SaveCreditCardTransaction)
      transaction = kclass.new(transaction_attrs, contribution).charge!

      render json: { payment_status: transaction.status }
    rescue Exception => e
      render json: { payment_status: 'failed', message: e.message }
    end

    def pay_credit_card
      transaction_attrs = build_default_credit_card_hash

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
        }.update(metadata_hash).update(customer_hash)
      }.merge!({ user: params[:user] })

      transaction = SlipTransaction.new(permited_attrs(slip_attrs), contribution).charge!

      render json: { boleto_url: transaction.boleto_url, payment_status: transaction.status }
    rescue PagarMe::PagarMeError => e
      render json: { boleto_url: nil, payment_status: 'failed', message: e.message }
    end

    protected

    def build_default_credit_card_hash
      hash = {
        payment_method: 'credit_card',
        card_number: params[:payment_card_number],
        card_holder_name: params[:payment_card_name],
        card_expiration_month: splited_month_and_year[0],
        card_expiration_year: splited_month_and_year[1],
        card_cvv: params[:payment_card_source],
        amount: delegator.value_with_installment_tax(get_installment),
        postback_url: ipn_pagarme_url(contribution),
        installments: get_installment,
      }
      hash.update(customer_hash)
      hash.update(metadata_hash)

      if has_subscription?
        hash.update({
          subscription_id: params[:subscription_id],
        })
      end

      hash
    end

    def customer_hash
      user = contribution.user

      {
        customer: {
          email: user.email,
          name: user.name
        }
      }
    end

    def metadata_hash
      {
        metadata: {
          project_name: contribution.project.name,
          project_status: contribution.project.state,
          compensation_date: contribution.created_at + 30.days
        }
      }
    end

    def get_installment
      if contribution.value < CatarsePagarme.configuration.minimum_value_for_installment
        1
      elsif params[:payment_card_installments].to_i > 0
        params[:payment_card_installments].to_i
      else
        1
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
  end
end
