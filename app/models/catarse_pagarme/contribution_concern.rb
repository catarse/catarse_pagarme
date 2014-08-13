module CatarsePagarme::ContributionConcern
  extend ActiveSupport::Concern

  included do
    def pagarme_delegator
      CatarsePagarme::PagarmeDelegator.new(self)
    end
  end
end
