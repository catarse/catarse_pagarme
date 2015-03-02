require 'spec_helper'

describe CatarsePagarme::ContributionDelegator do
  let(:contribution) { create(:contribution, value: 10) }
  let(:delegator) { contribution.pagarme_delegator }

  context "instance of CatarsePagarme::ContributionDelegator" do
    it { expect(delegator).to be_a CatarsePagarme::ContributionDelegator }
  end

  context "#value_for_transaction" do
    subject { delegator.value_for_transaction }

    it "should convert contribution value to pagarme value format" do
      expect(subject).to eq(1000)
    end
  end

  context "#value_with_installment_tax" do
    let(:installment) { 5 }
    subject { delegator.value_with_installment_tax(installment)}

    before do
      CatarsePagarme.configuration.stub(:interest_rate).and_return(1.8)
    end

    it "should return the contribution value with installments tax" do
      expect(subject).to eq(1057)
    end
  end

  context "#get_fee" do
    let(:fake_transaction) {
      t = double
      t.stub(:card_brand).and_return('visa')
      t.stub(:acquirer_name).and_return('stone')
      t.stub(:acquirer_tid).and_return('404040404')
      t
    }

    before do
      CatarsePagarme.configuration.stub(:slip_tax).and_return(2.00)
      CatarsePagarme.configuration.stub(:credit_card_tax).and_return(0.01)
      CatarsePagarme.configuration.stub(:pagarme_tax).and_return(0.0063)
      CatarsePagarme.configuration.stub(:cielo_tax).and_return(0.038)
      CatarsePagarme.configuration.stub(:stone_tax).and_return(0.0307)

      delegator.stub(:transaction).and_return(fake_transaction)
    end

    context 'when choice is slip' do
      let(:contribution) { create(:contribution, value: 10, payment_choice: CatarsePagarme::PaymentType::SLIP) }
      subject { delegator.get_fee.to_f }
      it { expect(subject).to eq(2.00) }
    end

    context 'when choice is credit card' do
      let(:contribution) { create(:contribution, value: 10, payment_choice: CatarsePagarme::PaymentType::CREDIT_CARD) }
      subject { delegator.get_fee.to_f }
      it { expect(subject).to eq(0.83) }
    end
  end

  context "#get_installments" do
    before do
      delegator.stub(:value_for_transaction).and_return(10000)
    end
    subject { delegator.get_installments }

    it { expect(subject['installments'].size).to eq(12) }
    it { expect(subject['installments']['2']['installment_amount']).to eq(5000) }
  end

  context "#change_status_by_transaction" do

    %w(paid authorized).each do |status|
      context "when status is #{status}" do
        context "and contribution is already confirmed" do
          before do
            contribution.stub(:confirmed?).and_return(true)
            contribution.should_not_receive(:confirm)
          end

          it { delegator.change_status_by_transaction(status) }
        end

        context "and contribution is not confirmed" do
          before do
            contribution.stub(:confirmed?).and_return(false)
            contribution.should_receive(:confirm)
          end

          it { delegator.change_status_by_transaction(status) }
        end
      end
    end

    %w(waiting_payment processing).each do |status|
      context "when status is #{status}" do
        context "and contribution is already waiting confirmation" do
          before do
            contribution.stub(:waiting_confirmation?).and_return(true)
            contribution.should_not_receive(:waiting)
          end

          it { delegator.change_status_by_transaction(status) }
        end

        context "and contribution is pending" do
          before do
            contribution.stub(:waiting_confirmation?).and_return(false)
            contribution.should_receive(:waiting)
          end

          it { delegator.change_status_by_transaction(status) }
        end
      end
    end

    context "when status is refunded" do
      context "and contribution is already refunded" do
        before do
          contribution.stub(:refunded?).and_return(true)
          contribution.should_not_receive(:refund)
        end

        it { delegator.change_status_by_transaction('refunded') }
      end

      context "and contribution is not refunded" do
        before do
          contribution.stub(:refunded?).and_return(false)
          contribution.should_receive(:refund)
        end

        it { delegator.change_status_by_transaction('refunded') }
      end
    end

    context "when status is refused" do
      context "and contribution is already canceled" do
        before do
          contribution.stub(:canceled?).and_return(true)
          contribution.should_not_receive(:cancel)
        end

        it { delegator.change_status_by_transaction('refused') }
      end

      context "and contribution is not canceled" do
        before do
          contribution.stub(:canceled?).and_return(false)
          contribution.should_receive(:cancel)
        end

        it { delegator.change_status_by_transaction('refused') }
      end
    end

  end
end
