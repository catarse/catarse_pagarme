module CatarsePagarme
  class NotificationsController < CatarsePagarme::ApplicationController
    skip_before_filter :authenticate_user!

    def create
      if payment
        payment.payment_notifications.create(contribution: payment.contribution, extra_data: params.to_json)

        if valid_postback?
          delegator.change_status_by_transaction(params[:current_status])
          delegator.update_transaction

          return render nothing: true, status: 200
        end
      end

      render_invalid_postback_response
    end

    protected

    def payment
      @payment ||=  PaymentEngines.find_payment({ gateway_id: params[:id], gateway: 'Pagarme' })
    end

    def valid_postback?
      raw_post  = request.raw_post
      signature = request.headers['HTTP_X_HUB_SIGNATURE']
      PagarMe::Postback.valid_request_signature?(raw_post, signature)
    end

    def render_invalid_postback_response
      render json: {error: 'invalid postback'}, status: 400
    end
  end
end
