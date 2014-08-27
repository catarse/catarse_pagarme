module CatarsePagarme::ContributionConcern
  extend ActiveSupport::Concern

  included do
    def pagarme_delegator
      CatarsePagarme::ContributionDelegator.new(self)
    end
  end
end
