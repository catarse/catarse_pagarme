module CatarsePagarme
  class Engine < ::Rails::Engine
    isolate_namespace CatarsePagarme

    config.to_prepare do
      ::Contribution.send(:include, CatarsePagarme::ContributionConcern)
    end
  end
end
