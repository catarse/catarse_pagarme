module CatarsePagarme::BankAccountConcern
  extend ActiveSupport::Concern

  included do

    validate :must_be_valid_on_pagarme

    def must_be_valid_on_pagarme
      pagarme_errors.each do |p_error|
        _attr = attributes_parsed_from_pagarme[p_error.parameter_name.to_sym]
        errors.add(_attr, :invalid)
      end
    end

    private

    def pagarme_errors
      configure_pagarme
      bank_account = ::PagarMe::BankAccount.new(attributes_parsed_to_pagarme)

      begin
        bank_account.create

        true
      rescue Exception => e
        e.errors
      end
    end

    def attributes_parsed_to_pagarme
      {
        bank_code: self.bank.try(:code),
        agencia: self.agency,
        agencia_dv: self.agency_digit,
        conta: self.account,
        conta_dv: self.account_digit,
        legal_name: self.owner_name,
        document_number: self.owner_document
      }
    end

    def attributes_parsed_from_pagarme
      {
        bank_code: :bank,
        agencia: :agency,
        agencia_dv: :agency_digit,
        conta: :account,
        conta_dv: :account_digit,
        legal_name: :owner_name,
        document_number: :owner_document
      }
    end

    def configure_pagarme
      ::PagarMe.api_key = CatarsePagarme.configuration.api_key
    end
  end
end
