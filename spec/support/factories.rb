FactoryGirl.define do
  sequence :name do |n|
    "Foo bar #{n}"
  end

  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :uid do |n|
    "#{n}"
  end

  sequence :permalink do |n|
    "foo_page_#{n}"
  end

  factory :user do |f|
    f.name "Foo bar"
    f.email { generate(:email) }
  end

  factory :credi_card do |f|
    f.subscription_id { generate(:uid) }
    f.association :user, factory: :user
    f.last_digits '1235'
    f.card_brand 'visa'
  end

  factory :category do |f|
    f.name_pt { generate(:name) }
  end

  factory :bank do |f|
    f.name { generate(:uid) }
    f.code { generate(:uid) }
  end

  factory :bank_account do |f|
    f.association :bank
    f.account '1234'
    f.account_digit '1'
    f.agency '1'
    f.agency_digit '2'
    f.owner_name 'fooo'
    f.owner_document '9889'
  end

  factory :project do |f|
    f.name "Foo bar"
    f.permalink { generate(:permalink) }
    f.association :user, factory: :user
    f.association :category, factory: :category
    f.about_html "Foo bar"
    f.headline "Foo bar"
    f.goal 10000
    f.online_date Time.now
    f.online_days 5
    f.video_url 'http://vimeo.com/17298435'
    f.state 'online'
  end

  factory :contribution do |f|
    f.association :project, factory: :project
    f.association :user, factory: :user
    f.confirmed_at Time.now
    f.value 10.00
    f.state 'confirmed'
    f.credits false
    f.payment_id '1.2.3'
  end
end


