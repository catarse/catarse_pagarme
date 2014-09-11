require 'spec_helper'

describe CatarsePagarme::SubscriptionsController do
  before do
    PaymentEngines.stub(:find_payment).and_return(contribution)
    controller.stub(:current_user).and_return(user)
  end

  let(:project) { create(:project, goal: 10_000, state: 'online') }
  let(:contribution) { create(:contribution, value: 10, project: project) }
  let(:credit_card) { create(:credit_card, subscription_id: '1542')}

  describe "pay with a saved credit card" do
    context 'without an user' do
      let(:user) { nil }

      it 'should raise a error' do
        expect {
          post :create, { locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme' }
        }.to raise_error('invalid user')
      end
    end

    context 'with an user' do
      let(:user) { contribution.user }
      context 'when subscription_id not associated with contribution user' do
        before do
          put :update, { locale: :pt, subscription_id: '1542', project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme' }
        end

        it 'payment_status should be failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).to eq('failed')
        end

        it 'message should be filled' do
          expect(ActiveSupport::JSON.decode(response.body)['message']).to eq('invalid subscription')
        end
      end
    end
  end

  describe 'pay and save credit card' do
    context 'without an user' do
      let(:user) { nil }

      it 'should raise a error' do
        expect {
          post :create, { locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme' }
        }.to raise_error('invalid user')
      end
    end

    context "with an user" do
      let(:user) { contribution.user }

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

      context "with valid card data" do
        before do
          post :create, {
            locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme',
            payment_card_date: '10/17', payment_card_number: '4901720080344448', payment_card_name: 'Foo bar',
            payment_card_source: '143', payment_card_installments: '1' }
        end

        it "should save card data into user" do
          expect(user.credit_cards.count).to eq(1)
        end

        it 'payment_status should be filled and not failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).not_to be_nil
        end

        it 'and payment_status is not failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).not_to eq('failed')
        end
      end
    end
  end
end
