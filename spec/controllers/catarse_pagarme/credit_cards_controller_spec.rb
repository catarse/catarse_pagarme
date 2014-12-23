require 'spec_helper'

describe CatarsePagarme::CreditCardsController do
  before do
    PaymentEngines.stub(:find_payment).and_return(contribution)
    controller.stub(:current_user).and_return(user)
  end

  let(:project) { create(:project, goal: 10_000, state: 'online') }
  let(:contribution) { create(:contribution, value: 10, project: project) }
  let(:credit_card) { create(:credit_card, subscription_id: '1542')}

  describe 'pay with credit card' do
    context  'without an user' do
      let(:user) { nil }

      it 'should raise a error' do
        expect {
          post :create, { locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme' }
        }.to raise_error('invalid user')
      end
    end

    context 'with an user' do
      let(:user) { contribution.user }
      context "with valid card data" do
        before do
          post :create, {
            locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme',
            payment_card_date: '10/17', payment_card_number: '4012888888881881', payment_card_name: 'Foo bar',
            payment_card_source: '574', payment_card_installments: '1' }

        end

        it 'payment_status should be filled' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).not_to be_nil
        end

        it 'and payment_status is not failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).not_to eq('failed')
        end
      end

      context 'with invalid card data' do
        before do
          post :create, {
            locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme',
            payment_card_date: '', payment_card_name: '',
            payment_card_source: '143', payment_card_installments: '1' }
        end

        it 'payment_status should be failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).to eq('failed')
        end

        it 'message should be filled' do
          expect(ActiveSupport::JSON.decode(response.body)['message']).not_to be_nil
        end
      end
    end
  end
end
