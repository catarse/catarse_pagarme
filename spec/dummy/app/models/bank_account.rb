class BankAccount < ActiveRecord::Base
  belongs_to :user
  belongs_to :bank

  validates :bank_id, :agency, :agency_digit, :account, :owner_name, :owner_document, :account_digit, presence: true
end
