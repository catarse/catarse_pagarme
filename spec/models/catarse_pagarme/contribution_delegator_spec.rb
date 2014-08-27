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

  context "#get_fee" do
    before do
      CatarsePagarme.configuration.stub(:slip_tax).and_return(2.00)
      CatarsePagarme.configuration.stub(:credit_card_tax).and_return(0.01)
    end

    context 'when choice is slip' do
      subject { delegator.get_fee(CatarsePagarme::PaymentType::SLIP).to_f }
      it { expect(subject).to eq(2.00) }
    end

    context 'when choice is credit card' do
      subject { delegator.get_fee(CatarsePagarme::PaymentType::CREDIT_CARD).to_f }
      it { expect(subject).to eq(0.49) }
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
