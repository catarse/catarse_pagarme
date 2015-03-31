require 'spec_helper'

describe CatarsePagarme::PaymentDelegator do
  let(:contribution) { create(:contribution, value: 10) }
  let(:payment) { contribution.payments.first }
  let(:delegator) { payment.pagarme_delegator }

  context "instance of CatarsePagarme::paymentDelegator" do
    it { expect(delegator).to be_a CatarsePagarme::PaymentDelegator }
  end

  context "#value_for_transaction" do
    subject { delegator.value_for_transaction }

    it "should convert payment value to pagarme value format" do
      expect(subject).to eq(1000)
    end
  end

  context "#value_with_installment_tax" do
    let(:installment) { 5 }
    subject { delegator.value_with_installment_tax(installment)}

    before do
      CatarsePagarme.configuration.stub(:interest_rate).and_return(1.8)
    end

    it "should return the payment value with installments tax" do
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
      CatarsePagarme.configuration.stub(:credit_card_cents_fee).and_return(0.39)

      delegator.stub(:transaction).and_return(fake_transaction)
    end

    context 'when choice is credit card and acquirer_name is nil' do
      let(:payment) { create(:payment, value: 10, payment_method: CatarsePagarme::PaymentType::CREDIT_CARD, gateway_data: {acquirer_name: nil}) }
      subject { delegator.get_fee }
      it { expect(subject).to eq(nil) }
    end

    context 'when choice is slip' do
      let(:payment) { create(:payment, value: 10, payment_method: CatarsePagarme::PaymentType::SLIP, gateway_data: {acquirer_name: nil}) }
      subject { delegator.get_fee }
      it { expect(subject).to eq(2.00) }
    end

    context 'when choice is credit card' do
      let(:payment) { create(:payment, value: 10, payment_method: CatarsePagarme::PaymentType::CREDIT_CARD, gateway_data: {acquirer_name: 'stone', card_brand: 'visa'}, installments: 1) }
      subject { delegator.get_fee }
      it { expect(subject).to eq(0.76) }
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
        context "and payment is already paid" do
          before do
            payment.stub(:paid?).and_return(true)
            payment.should_not_receive(:pay)
          end

          it { delegator.change_status_by_transaction(status) }
        end

        context "and payment is not paid" do
          before do
            payment.stub(:paid?).and_return(false)
            payment.should_receive(:pay)
          end

          it { delegator.change_status_by_transaction(status) }
        end
      end
    end

    context "when status is refunded" do
      context "and payment is already refunded" do
        before do
          payment.stub(:refunded?).and_return(true)
          payment.should_not_receive(:refund)
        end

        it { delegator.change_status_by_transaction('refunded') }
      end

      context "and payment is not refunded" do
        before do
          payment.stub(:refunded?).and_return(false)
          payment.should_receive(:refund)
        end

        it { delegator.change_status_by_transaction('refunded') }
      end
    end

    context "when status is refused" do
      context "and payment is already canceled" do
        before do
          payment.stub(:refused?).and_return(true)
          payment.should_not_receive(:refuse)
        end

        it { delegator.change_status_by_transaction('refused') }
      end

      context "and payment is not refused" do
        before do
          payment.stub(:refused?).and_return(false)
          payment.should_receive(:refuse)
        end

        it { delegator.change_status_by_transaction('refused') }
      end
    end

  end
end
