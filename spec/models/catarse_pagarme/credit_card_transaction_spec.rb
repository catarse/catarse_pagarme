require 'spec_helper'

describe CatarsePagarme::CreditCardTransaction do
  let(:payment) { create(:payment, value: 100) }

  let(:pagarme_transaction) {
    double({
      id: 'abcd',
      charge: true,
      status: 'paid',
      boleto_url: nil,
      installments: 3,
      acquirer_name: 'stone',
      tid: '123123',
      card_brand: 'visa'
    })
  }

  let(:valid_attributes) do
      {
        payment_method: 'credit_card',
        card_number: '4901720080344448',
        card_holder_name: 'Foo bar',
        card_expiration_month: '10',
        card_expiration_year: '19',
        card_cvv: '434',
        amount: payment.pagarme_delegator.value_for_transaction,
        postback_url: 'http://test.foo',
        installments: 1
      }
  end

  let(:card_transaction) { CatarsePagarme::CreditCardTransaction.new(valid_attributes, payment) }

  before do
    PagarMe::Transaction.stub(:new).and_return(pagarme_transaction)
    CatarsePagarme::PaymentDelegator.any_instance.stub(:change_status_by_transaction).and_return(true)
    CatarsePagarme.configuration.stub(:credit_card_tax).and_return(0.01)
  end

  describe '#charge!' do
    describe 'with valid attributes' do
      before do
        payment.should_receive(:update_attributes).at_least(1).and_call_original
        PagarMe::Transaction.should_receive(:find_by_id).with(pagarme_transaction.id).and_return(pagarme_transaction)
        CatarsePagarme::PaymentDelegator.any_instance.should_receive(:change_status_by_transaction).with('paid')

        card_transaction.charge!
        payment.reload
      end

      it "should update payment payment_id" do
        expect(payment.gateway_id).to eq('abcd')
      end

      it "should update payment payment_service_fee" do
        expect(payment.gateway_fee.to_f).to eq(4.08)
      end

      it "should update payment payment_method" do
        expect(payment.gateway).to eq('Pagarme')
      end

      it "should update payment installments" do
        expect(payment.installments).to eq(3)
      end

      it "should update payment payment_choice" do
        expect(payment.payment_method).to eq(CatarsePagarme::PaymentType::CREDIT_CARD)
      end

      it "should update payment acquirer_name" do
        expect(payment.gateway_data["acquirer_name"]).to eq('stone')
      end

      it "should update payment acquirer_tid" do
        expect(payment.gateway_data["acquirer_tid"]).to eq('123123')
      end

      it "should update payment installment_value" do
        expect(payment.installment_value).to_not be_nil
      end
    end
  end

end
