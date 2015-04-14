require 'spec_helper'

describe CatarsePagarme::SlipController do
  before do
    controller.stub(:current_user).and_return(user)
    Bank.create(name: 'foo', code: '123')
  end

  let(:project) { create(:project, goal: 10_000, state: 'online') }
  let(:contribution) { create(:contribution, value: 10, project: project) }
  let(:payment) { contribution.payments.first }
  let(:credit_card) { create(:credit_card, subscription_id: '1542')}

  describe 'PATCH update' do
    let(:user) { payment.user }

    before do
      patch :update, locale: :pt, id: contribution.id, use_route: 'catarse_pagarme'
    end

    context 'with valid bank account data' do
      it 'boleto_url should be filled' do
        expect(response.body).to be_present
      end
    end
  end

  describe 'POST create' do
    context  'without an user' do
      let(:user) { nil }

      it 'should raise a error' do
        expect {
          post :create, { locale: :pt, id: contribution.id, use_route: 'catarse_pagarme' }
        }.to raise_error('invalid user')
      end
    end

    context 'with an user' do
      let(:user) { payment.user }

      context 'with valid bank account data' do
        before do
          post :create, {
            locale: :pt, id: contribution.id, use_route: 'catarse_pagarme',
            user: { bank_account_attributes: {
              bank_id: Bank.first.id, agency: '1', agency_digit: '1', account: '1', account_digit: '1', owner_name: 'foo', owner_document: '1'
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
        let(:user) { payment.user }

        before do
          post :create, { locale: :pt, id: contribution.id, use_route: 'catarse_pagarme', user: { bank_account_attributes: { owner_name: '' } } }
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


