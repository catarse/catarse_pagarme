require 'spec_helper'

describe CatarsePagarme::SlipTransaction do
  let(:contribution) { create(:contribution, value: 100) }
  let(:pagarme_transaction) {
    transaction = double
    transaction.stub(:id).and_return('abcd')
    transaction.stub(:charge).and_return(true)
    transaction.stub(:status).and_return('paid')
    transaction.stub(:boleto_url).and_return('boleto url')
    transaction.stub(:installments).and_return(nil)
    transaction
  }
  let(:valid_attributes) do
    {
      slip_payment: {
        payment_method: 'boleto',
        amount: contribution.pagarme_delegator.value_for_transaction,
        postback_url: 'http://test.foo'
      }, user: {
        bank_account_attributes: {
          name: 'foo', agency: '1', agency_digit: '1',
          account: '1', account_digit: '1', user_name: 'foo',
          user_document: 'bar'
        }
      }
    }
  end

  let(:invalid_attributes) do
    {
      slip_payment: {
        payment_method: 'boleto',
        amount: contribution.pagarme_delegator.value_for_transaction,
        postback_url: 'http://test.foo'
      }, user: {
        bank_account_attributes: {
          name: ''
        }
      }
    }
  end

  let(:slip_transaction) { CatarsePagarme::SlipTransaction.new(valid_attributes, contribution) }

  before do
    PagarMe::Transaction.stub(:new).and_return(pagarme_transaction)
    CatarsePagarme::ContributionDelegator.any_instance.stub(:change_status_by_transaction).and_return(true)
  end

  context "#user" do
    subject { slip_transaction.user }
    it { expect(subject).to eq(contribution.user) }
  end

  context "#charge!" do
    context "with invalid attributes" do
      let(:slip_transaction) {
        CatarsePagarme::SlipTransaction.new(invalid_attributes, contribution)
      }

      it "should raises an error" do
        expect {
          slip_transaction.charge!
        }.to raise_error(PagarMe::PagarMeError)
      end
    end

    context "with valid attributes" do
      before do
        slip_transaction.should_receive(:update_user_bank_account).and_call_original
        slip_transaction.user.should_receive(:update_attributes).and_return(true)
        contribution.should_receive(:update_attributes).and_call_original
        CatarsePagarme::ContributionDelegator.any_instance.should_receive(:change_status_by_transaction).with('paid')

        slip_transaction.charge!
        contribution.reload
      end

      it "should update contribution payment_id" do
        expect(contribution.payment_id).to eq('abcd')
      end

      it "should update contribution payment_service_fee" do
        expect(contribution.payment_service_fee).to eq(0.0)
      end

      it "should update contribution payment_method" do
        expect(contribution.payment_method).to eq('Pagarme')
      end

      it "should update contribution slip_url" do
        expect(contribution.slip_url).to eq('boleto url')
      end

      it "should update contribution payment_choice" do
        expect(contribution.payment_choice).to eq(CatarsePagarme::PaymentType::SLIP)
      end
    end
  end

end
