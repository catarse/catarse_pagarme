module CatarsePagarme::BalanceTransferPingConcern
  extend ActiveSupport::Concern

  included do
    def pagarme_delegator
      CatarsePagarme::BalanceTransferPingDelegator.new(self)
    end
  end
end
