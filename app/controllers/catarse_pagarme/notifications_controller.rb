module CatarsePagarme
  class NotificationsController < CatarsePagarme::ApplicationController
    skip_before_filter :authenticate_user!
    skip_before_filter :force_http

    def create
      if contribution
        contribution.payment_notifications.create(extra_data: params.to_json)

        if PagarMe::validate_fingerprint(contribution.try(:payment_id), params[:fingerprint])
          delegator.change_status_by_transaction(params[:current_status])
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
