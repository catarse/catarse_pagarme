require 'spec_helper'

describe CatarsePagarme::PagarmeController do
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
          post :pay_with_subscription, { locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme' }
        }.to raise_error('invalid user')
      end
    end

    context 'with an user' do
      let(:user) { contribution.user }
      context 'when subscription_id not associated with contribution user' do
        before do
          post :pay_with_subscription, { locale: :pt, subscription_id: '1542', project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme' }
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
          post :pay_with_subscription, { locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme' }
        }.to raise_error('invalid user')
      end
    end

    context "with an user" do
      let(:user) { contribution.user }

      context 'with invalid card data' do
        before do
          post :pay_with_subscription, {
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
          post :pay_with_subscription, {
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

  describe 'pay with credit card' do
    context  'without an user' do
      let(:user) { nil }

      it 'should raise a error' do
        expect {
          post :pay_credit_card, { locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme' }
        }.to raise_error('invalid user')
      end
    end

    context 'with an user' do
      let(:user) { contribution.user }
      context "with valid card data" do
        before do
          post :pay_credit_card, {
            locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme',
            payment_card_date: '10/17', payment_card_number: '4901720080344448', payment_card_name: 'Foo bar',
            payment_card_source: '143', payment_card_installments: '1' }

        end

        it 'payment_status should be filled and not failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).not_to be_nil
        end

        it 'and payment_status is not failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).not_to eq('failed')
        end
      end

      context 'with invalid card data' do
        before do
          post :pay_credit_card, {
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


  describe 'pay with slip' do
    context  'without an user' do
      let(:user) { nil }

      it 'should raise a error' do
        expect {
          post :pay_slip, { locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme' }
        }.to raise_error('invalid user')
      end
    end

    context 'with an user' do
      let(:user) { contribution.user }

      context 'with valid bank account data' do
        before do
          post :pay_slip, {
            locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme',
            user: { bank_account_attributes: {
              name: 'bank', agency: '1', agency_digit: '1', account: '1', account_digit: '1', user_name: 'foo', user_document: '1'
            } } }
        end

        it 'boleto_url should be filled' do
          expect(ActiveSupport::JSON.decode(response.body)['boleto_url']).not_to be_nil
        end

        it 'payment_status should be waiting_payment' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).to eq 'waiting_payment'
        end
      end

      context 'with invalid bank account data' do
        let(:user) { contribution.user }

        before do
          post :pay_slip, { locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme', user: { bank_account_attributes: { name: '' } } }
        end

        it 'boleto_url should be nil' do
          expect(ActiveSupport::JSON.decode(response.body)['boleto_url']).to be_nil
        end

        it 'payment_status should be failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).to eq 'failed'
        end

        it 'message should be filled' do
          expect(ActiveSupport::JSON.decode(response.body)['message']).not_to be_nil
        end
      end
    end
  end
end

