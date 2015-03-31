require 'spec_helper'

describe CatarsePagarme::CreditCardsController do
  before do
    PaymentEngines.stub(:find_payment).and_return(payment)
    controller.stub(:current_user).and_return(user)
  end

  let(:project) { create(:project, goal: 10_000, state: 'online') }
  let(:contribution) { create(:contribution, value: 10, project: project) }
  let(:payment) { contribution.payments.first }

  describe 'pay with credit card' do
    context  'without an user' do
      let(:user) { nil }

      it 'should raise a error' do
        expect {
          post :create, { locale: :pt, project_id: project.id, payment_id: payment.id, use_route: 'catarse_pagarme' }
        }.to raise_error('invalid user')
      end
    end

    context 'with an user' do
      let(:user) { payment.user }
      context "with valid card data" do
        before do
          post :create, {
            locale: :pt, project_id: project.id, payment_id: payment.id, use_route: 'catarse_pagarme',
            card_hash: sample_card_hash }
        end

        it 'and payment_status is not failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).not_to eq('failed')
        end
      end

      context 'with invalid card data' do
        before do
          post :create, {
            locale: :pt, project_id: project.id, payment_id: payment.id, use_route: 'catarse_pagarme', card_hash: "abcd" }
        end

        it 'payment_status should be failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).to eq('failed')
        end
      end
    end
  end
end
