module CatarsePagarme
  class NotificationsController < CatarsePagarme::ApplicationController
    skip_before_filter :authenticate_user!

    def create
      if contribution
        contribution.payment_notifications.create(extra_data: params.to_json)

        if PagarMe::validate_fingerprint(contribution.try(:payment_id), params[:fingerprint])

          if params[:current_status] == 'paid' && params[:desired_status] == 'refunded'
            contribution.try(:invalid_refund)
          else
            delegator.change_status_by_transaction(params[:current_status])
            delegator.update_fee
          end

          return render nothing: true, status: 200
        end
      end

      render nothing: true, status: 404
    end

    protected

    def contribution
      @contribution ||=  PaymentEngines.find_payment({ payment_id: params[:id] })
    end
  end
end
