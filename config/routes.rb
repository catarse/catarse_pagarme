CatarsePagarme::Engine.routes.draw do
  resources :pagarme, only: [], path: "payment/pagarme" do

    member do
      get  :review
      get  :slip_data, to: 'slip#slip_data'
      get  :second_slip, to: 'slip#update'
      get  :credit_cards, to: 'credit_cards#get_saved_cards'
      get  :get_installment, to: 'credit_cards#get_installment_json'
      post :pay_credit_card, to: 'credit_cards#create'
      post :pay_slip, to: 'slip#create'
    end

    collection do
      post :ipn, to: 'notifications#create'
    end

  end
end
