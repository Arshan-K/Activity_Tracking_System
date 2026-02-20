FactoryBot.define do
  factory :lead do
    name { Faker::Name.name }
    status { "new" }
    phone { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.email }
    budget { Faker::Number.decimal(l_digits: 5, r_digits: 2) }
    agent_id { Faker::Number.between(from: 1, to: 5) }

    trait :contacted do
      status { "contacted" }
    end

    trait :qualified do
      status { "qualified" }
    end

    trait :won do
      status { "won" }
    end

    trait :lost do
      status { "lost" }
    end

    trait :with_high_budget do
      budget { Faker::Number.between(from: 50000, to: 100000) }
    end

    trait :with_low_budget do
      budget { Faker::Number.between(from: 1000, to: 10000) }
    end
  end
end
