module CatarsePagarme
  class AntifraudOrderWrapper
    attr_accessor :attributes, :transaction

    def initialize(attributes, transaction)
      self.attributes = attributes
      self.transaction = transaction
    end

    def send(analyze:)
      order = build_order(analyze: analyze)
      client.analyze(order)
    end

    private

    def client
      konduto_api_key = CatarsePagarme.configuration.konduto_api_key
      @client ||= KondutoRuby.new(konduto_api_key)
    end

    def build_order(analyze:)
      KondutoOrder.new(
        order_attributes.merge({
          analyze: analyze,
          customer: build_customer,
          payment: build_payment,
          billing: build_billing_address,
          shipping: build_shipping_address,
          shopping_cart: build_shopping_cart,
          seller: build_seller
        })
      )
    end

    def build_customer
      KondutoCustomer.new(customer_attributes)
    end

    def build_payment
      [KondutoPayment.new(payment_attributes)]
    end

    def build_billing_address
      KondutoAddress.new(billing_address_attributes)
    end

    def build_shipping_address
      KondutoAddress.new(shipping_address_attributes)
    end

    def build_shopping_cart
      [KondutoItem.new(item_attributes)]
    end

    def build_seller
      KondutoSeller.new(seller_attributes)
    end

    def order_attributes
      {
        id: self.transaction.id.to_s,
        total_amount: self.attributes[:amount] / 100.0,
        visitor: self.attributes.dig(:metadata, :contribution_id).to_s,
        currency: 'BRL',
        installments: self.attributes[:installments],
        purchased_at: self.transaction.date_created,
        ip: self.attributes.dig(:antifraud_metadata, :ip)
      }
    end

    def customer_attributes
      customer = self.attributes.dig(:customer)
      {
        id: customer[:document_number],
        name: customer[:name],
        email: customer[:email],
        phone1: customer[:phone].to_h.values.join,
        created_at: self.attributes.dig(:antifraud_metadata, :register, :registered_at)
      }
    end

    def payment_attributes
      {
        type: 'credit',
        status: self.transaction.status == 'authorized' ? 'approved' : 'declined',
        bin: self.transaction.card.first_digits,
        last4: self.transaction.card.last_digits,
        expiration_date: card_expiration_date
      }
    end

    def billing_address_attributes
      billing_data = self.attributes.dig(:antifraud_metadata, :billing)
      {
        name: self.transaction.card.holder_name,
        address1: billing_data.dig(:address, :street),
        city: billing_data.dig(:address, :city),
        state: billing_data.dig(:address, :state),
        zip: billing_data.dig(:address, :zipcode),
        country: card_country_code
      }
    end

    def shipping_address_attributes
      shipping_data = self.attributes.dig(:antifraud_metadata, :shipping)
      {
        name: shipping_data.dig(:customer, :name),
        address1: shipping_data.dig(:address, :street),
        city: shipping_data.dig(:address, :city),
        state: shipping_data.dig(:address, :state),
        zip: shipping_data.dig(:address, :zipcode)
      }
    end

    def item_attributes
      shopping_cart_data = self.attributes.dig(:antifraud_metadata, :shopping_cart).first
      {
        sku: self.attributes.dig(:metadata, :contribution_id).to_s,
        product_code: self.attributes.dig(:metadata, :contribution_id).to_s,
        category: 9999,
        name: shopping_cart_data[:name],
        unit_cost: self.attributes[:amount] / 100.0,
        quantity: 1,
        created_at: self.attributes.dig(:metadata, :project_online).to_s[0..9]
      }
    end

    def seller_attributes
      event_data = self.attributes.dig(:antifraud_metadata, :events).first
      {
        id: event_data[:id],
        name: event_data[:venue_name],
        created_at: event_data[:date]
      }
    end

    def card_expiration_date
      expiration_date = self.transaction.card.expiration_date
      "#{expiration_date[0..1]}20#{expiration_date[2..3]}"
    end

    def card_country_code
      country = ::ISO3166::Country.find_country_by_name(self.transaction.card.country)
      country.alpha2
    end
  end
end
