require 'spec_helper'

describe CatarsePagarme::PagarmeController do
  before do
    PaymentEngines.stub(:find_payment).and_return(contribution)
    controller.stub(:current_user).and_return(user)
  end

  describe 'pay with slip' do
    let(:project) { create(:project, goal: 10_000, state: 'online') }
    let(:contribution) { create(:contribution, value: 10, project: project) }
    let(:user) { nil }

    context  'without an user' do
      it 'should raise a error' do
        expect {
          post :pay_slip, { locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme' }
        }.to raise_error('invalid user')
      end
    end

    context 'with an user' do
      context 'invalid bank account data' do
        let(:user) { contribution.user }

        before do
          controller.stub(:current_user).and_return(user)

          post :pay_slip, { locale: :pt, project_id: project.id, contribution_id: contribution.id, use_route: 'catarse_pagarme', user: { bank_account_attributes: { name: '' } } }
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

