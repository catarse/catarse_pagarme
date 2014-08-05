CatarsePagarme::Engine.routes.draw do
  resources :pagarme, only: [], path: "payment/pagarme" do

    collection do
      post :ipn
    end

    member do
      get  :review
      post :pay
    end

  end
end
