module CatarsePagarme
  class NotificationsController < ApplicationController
    skip_before_filter :authenticate_user!

    def create
      if PagarMe::validate_fingerprint(contribution.try(:payment_id), params[:fingerprint])
        if contribution
          contribution.payment_notifications.create(extra_data: params.to_json)
          delegator.change_status_by_transaction(params[:current_status])

          return render nothing: true, status: 200
        end

        return render nothing: true, status: 404
      end

      render nothing: true, status: 404
    end
  end
end