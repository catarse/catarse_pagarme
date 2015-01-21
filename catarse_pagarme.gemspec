# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "catarse_pagarme/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "catarse_pagarme"
  s.version     = CatarsePagarme::VERSION
  s.authors     = ["Antônio Roberto Silva", "Diogo Biazus"]
  s.email       = ["forevertonny@gmail.com", "diogob@gmail.com"]
  s.homepage    = "http://github.com/catarse/catarse_pagarme"
  s.summary     = "Integration with Pagar.me"
  s.description = "Pagar.me engine for catarse"

  s.files      = `git ls-files`.split($\)
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.add_dependency "rails", "~> 4.0"
  s.add_dependency "pagarme", "~> 1.9.9"

  s.add_development_dependency "rspec-rails", "~> 2.14.0"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "pg"
end
