# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../dummy/config/environment", __FILE__)

require 'pagarme'
require 'rspec/rails'
require 'factory_girl'
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[ File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.use_transactional_examples = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    PagarMe.stub(:api_key).and_return('ak_test_Rw4JR98FmYST2ngEHtMvVf5QJW7Eoo')
    PaymentEngines.stub(:configuration).and_return({})
  end
end
