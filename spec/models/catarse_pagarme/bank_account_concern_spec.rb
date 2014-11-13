require 'spec_helper'

class FakeBankAccount < BankAccount
  include CatarsePagarme::BankAccountConcern

  validate :must_be_valid_on_pagarme
end

describe FakeBankAccount do
  let(:bank) { create(:bank) }
  let(:valid_attr) do
    vb = build(:bank_account, bank: bank)
    vb.attributes
  end

  describe "validate :must_be_valid_on_pagarme" do
    context "when bank account has invalid data on pagarme" do
      let(:bank_account_on_pagarme) { FakeBankAccount.new(valid_attr) }
      let(:local_bank_account) { BankAccount.new(valid_attr) }

      it "local_bank_account should be valid" do
        expect(local_bank_account.valid?).to be_true
      end

      it "local_bank_account should be valid" do
        expect(bank_account_on_pagarme.valid?).to be_false
      end
    end
  end
end
