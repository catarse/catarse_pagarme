module CatarsePagarme
  class PagarmeController < CatarsePagarme::ApplicationController

    def review
      contribution
      current_user.build_bank_account unless current_user.bank_account
    end

    def pay_slip
      slip_attrs = {
        slip_payment: {
          payment_method: 'boleto',
          amount: delegator.value_for_transaction,
          postback_url: ipn_pagarme_url(contribution),
          customer: {
            email: contribution.user.email,
            name: contribution.user.name
          }
        }
      }.merge!({ user: params[:user] })

      transaction = SlipTransaction.new(permited_attrs(slip_attrs), contribution).charge!

      render json: { boleto_url: transaction.boleto_url, payment_status: transaction.status }
    rescue PagarMe::PagarMeError => e
      render json: { boleto_url: nil, payment_status: 'failed', message: e.message }
    end

  end
end
