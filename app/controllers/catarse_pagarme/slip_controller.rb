require 'weekdays'

module CatarsePagarme
  class SlipController < CatarsePagarme::ApplicationController

    def create
      transaction = SlipTransaction.new(slip_attributes, payment).charge!

      render json: { boleto_url: transaction.boleto_url, payment_status: transaction.status }
    rescue PagarMe::PagarMeError => e
      raven_capture(e)
      render json: { boleto_url: nil, payment_status: 'failed', message: e.message }
    end

    def update
      transaction = SlipTransaction.new(slip_attributes, payment).charge!
      respond_to do |format|
        format.html { redirect_to transaction.boleto_url }
        format.json do
          { boleto_url: transaction.boleto_url }
        end
      end
    end

    def slip_data
      render json: {slip_expiration_date: payment.slip_expiration_date.to_date}
    end

    protected

    def slip_attributes
      {
        payment_method: 'boleto',
        boleto_expiration_date: payment.slip_expiration_date,
        amount: delegator.value_for_transaction,
        postback_url: ipn_pagarme_index_url(host: CatarsePagarme.configuration.host,
                                            subdomain: CatarsePagarme.configuration.subdomain,
                                            protocol: CatarsePagarme.configuration.protocol),
        customer: {
          email: payment.user.email,
          name: payment.user.name
        },
        metadata: metadata_attributes
      }
    end
  end
end
