module CatarsePagarme
  class NotificationsController < CatarsePagarme::ApplicationController
    skip_before_filter :authenticate_user!
    skip_before_filter :force_http

    def create
      Rails.logger.info "Start IPN"
      Rails.logger.info contribution.try(:payment_id)
      Rails.logger.info params[:fingerprint]
      if PagarMe::validate_fingerprint(contribution.try(:payment_id), params[:fingerprint])
        Rails.logger.info "GET FINGERPRINT"
        if contribution
          contribution.payment_notifications.create(extra_data: params.to_json)
          delegator.change_status_by_transaction(params[:current_status])

          return render nothing: true, status: 200
        end

        return render nothing: true, status: 404
      end

      Rails.logger.info "CANT CHECK FINGERPRINT :("

      render nothing: true, status: 404
    end
  end
end
