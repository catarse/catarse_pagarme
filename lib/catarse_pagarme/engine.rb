module CatarsePagarme
  class Engine < ::Rails::Engine
    isolate_namespace CatarsePagarme

    config.to_prepare do
      ::Contribution.send(:include, CatarsePagarme::ContributionConcern)
      ::CreditCard.send(:include, CatarsePagarme::CreditCardConcern)
      ::BankAccount.send(:include, CatarsePagarme::BankAccountConcern)
    end
  end
end
