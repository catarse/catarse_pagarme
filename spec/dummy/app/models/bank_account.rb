class BankAccount < ActiveRecord::Base
  belongs_to :user

  validates :name, :agency, :agency_digit, :account, :owner_name, :owner_document, :account_digit, presence: true
end
