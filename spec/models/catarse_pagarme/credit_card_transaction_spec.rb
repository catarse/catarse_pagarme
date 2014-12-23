require 'spec_helper'

describe CatarsePagarme::CreditCardTransaction do
  let(:contribution) { create(:contribution, value: 100) }

  let(:pagarme_transaction) {
    transaction = double
    transaction.stub(:id).and_return('abcd')
    transaction.stub(:charge).and_return(true)
    transaction.stub(:status).and_return('paid')
    transaction.stub(:boleto_url).and_return(nil)
    transaction.stub(:installments).and_return(3)
    transaction.stub(:acquirer_name).and_return('stone')
    transaction.stub(:tid).and_return('123123')
    transaction
  }

  let(:valid_attributes) do
      {
        payment_method: 'credit_card',
        card_number: '4901720080344448',
        card_holder_name: 'Foo bar',
        card_expiration_month: '10',
        card_expiration_year: '19',
        card_cvv: '434',
        amount: contribution.pagarme_delegator.value_for_transaction,
        postback_url: 'http://test.foo',
        installments: 1
      }
  end

  let(:card_transaction) { CatarsePagarme::CreditCardTransaction.new(valid_attributes, contribution) }

  before do
    PagarMe::Transaction.stub(:new).and_return(pagarme_transaction)
    CatarsePagarme::ContributionDelegator.any_instance.stub(:change_status_by_transaction).and_return(true)
    CatarsePagarme.configuration.stub(:credit_card_tax).and_return(0.01)
  end

  describe '#charge!' do
    describe 'with valid attributes' do
      before do
        contribution.should_receive(:update_attributes).at_least(1).and_call_original
        CatarsePagarme::ContributionDelegator.any_instance.should_receive(:change_status_by_transaction).with('paid')

        card_transaction.charge!
        contribution.reload
      end

      it "should update contribution payment_id" do
        expect(contribution.payment_id).to eq('abcd')
      end

      it "should update contribution payment_service_fee" do
        expect(contribution.payment_service_fee.to_f).to eq(4.08)
      end

      it "should update contribution payment_method" do
        expect(contribution.payment_method).to eq('Pagarme')
      end

      it "should update contribution installments" do
        expect(contribution.installments).to eq(3)
      end

      it "should update contribution payment_choice" do
        expect(contribution.payment_choice).to eq(CatarsePagarme::PaymentType::CREDIT_CARD)
      end

      it "should update contribution acquirer_name" do
        expect(contribution.acquirer_name).to eq('stone')
      end

      it "should update contribution acquirer_tid" do
        expect(contribution.acquirer_tid).to eq('123123')
      end

      it "should update contribution installment_value" do
        expect(contribution.installment_value).to_not be_nil
      end
    end
  end

end
