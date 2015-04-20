require 'spec_helper'

describe CatarsePagarme::NotificationsController do
  let(:fake_transaction) { double("fake transaction", card_brand: 'visa', acquirer_name: 'stone', tid: '404040404', installments: 2) }

  before do
    PagarMe.stub(:validate_fingerprint).and_return(true)
    PagarMe::Transaction.stub(:find_by_id).and_return(fake_transaction)
  end

  let(:project) { create(:project, goal: 10_000, state: 'online') }
  let(:contribution) { create(:contribution, value: 10, project: project) }
  let(:payment) { 
    p = contribution.payments.first 
    p.update_attributes gateway_id: 'abcd'
    p
  }
  let(:credit_card) { create(:credit_card, subscription_id: '1542')}

  describe 'CREATE' do
    context "with invalid payment" do
      before do
        PaymentEngines.stub(:find_payment).and_return(nil)
        post :create, { locale: :pt, id: 'abcdfg', use_route: 'catarse_pagarme' }
      end

      it "should not found the payment" do
        expect(response.code.to_i).to eq(404)
      end
    end

    context "with valid payment" do
      before do
        PaymentEngines.stub(:find_payment).and_return(payment)
        post :create, { locale: :pt, id: 'abcd', use_route: 'catarse_pagarme' }
      end

      it "should save an extra_data into payment_notifications" do
        expect(payment.payment_notifications.size).to eq(1)
      end

      it "should return 200 status" do
        expect(response.code.to_i).to eq(200)
      end
    end
  end

end

