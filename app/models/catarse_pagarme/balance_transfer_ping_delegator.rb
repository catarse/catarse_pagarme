module CatarsePagarme
  class BalanceTransferPingDelegator
    attr_accessor :balance_transfer_ping, :transfer

    def initialize(balance_transfer_ping)
      configure_pagarme
      self.balance_transfer_ping = balance_transfer_ping
    end

    def transfer_funds
      ActiveRecord::Base.transaction do
        raise "unable to create transfer ping, need to be authorized" if !balance_transfer_ping.authorized?

        bank_account = PagarMe::BankAccount.new(bank_account_attributes.delete(:bank_account))
        bank_account.create
        raise "unable to create an bank account" unless bank_account.id.present?

        transfer = PagarMe::Transfer.new({
          bank_account_id: bank_account.id,
          amount: value_for_transaction
        })
        transfer.create
        raise "unable to create a transfer ping" unless transfer.id.present?

        balance_transfer_ping.update_attributes(transfer_id: transfer.id,
          metadata: transfer.to_hash,
          state: 'processing')
        balance_transfer_ping
      end
    end

    def bank_account_attributes
      account = balance_transfer_ping.balance_transfer.project.account

      bank_account_attrs = {
        bank_account: {
          bank_code: (account.bank.code || account.bank.name),
          agencia: account.agency,
          agencia_dv: account.agency_digit,
          conta: account.account,
          conta_dv: account.account_digit,
          legal_name: account.owner_name[0..29],
          document_number: account.owner_document
        }
      }

      bank_account_attrs[:bank_account].delete(:agencia_dv) if account.agency_digit.blank?
      return bank_account_attrs
    end

    def configure_pagarme
      ::PagarMe.api_key = CatarsePagarme.configuration.api_key
    end

    def value_for_transaction
      (self.balance_transfer_ping.amount * 100).to_i
    end
  end
end
