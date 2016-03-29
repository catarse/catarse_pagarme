require 'spec_helper'

describe CatarsePagarme::CreditCardsController, type: :controller do
  before do
    @routes = CatarsePagarme::Engine.routes
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
          post :create, { locale: :pt, id: contribution.id }
        }.to raise_error('invalid user')
      end
    end

    context 'with an user' do
      let(:user) { payment.user }
      context "with valid card data" do
        before do
          allow(CatarsePagarme::CreditCardTransaction).to receive(:new).and_call_original
          post :create, {
            locale: :pt, id: contribution.id,
            card_hash: sample_card_hash }
        end

        it 'should receive soft descriptor with project name' do
          expect(CatarsePagarme::CreditCardTransaction).to have_received(:new).with(hash_including(soft_descriptor: payment.project.permalink.gsub(/[\W\_]/,' ')), anything)
        end

        it 'and payment_status is not failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).not_to eq('failed')
        end
      end

      context 'with invalid card data' do
        before do
          post :create, {
            locale: :pt, id: contribution.id, card_hash: "abcd" }
        end

        it 'payment_status should be failed' do
          expect(ActiveSupport::JSON.decode(response.body)['payment_status']).to eq('failed')
        end
      end

      context "when charges fails" do
        before do
          allow_any_instance_of(PagarMe::Transaction).to receive(:charge).and_raise(PagarMe::PagarMeError)
          post :create, {
            locale: :pt, id: contribution.id,
            card_hash: sample_card_hash }
        end

        it "should have created a payment" do
          expect(contribution.payments.size).to eq(2)
        end

        it "should update the payment key on the local database" do
          expect(contribution.payments.last.key).to_not be_nil
        end
      end
    end
  end
end
