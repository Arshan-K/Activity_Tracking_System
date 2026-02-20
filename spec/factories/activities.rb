FactoryBot.define do
  factory :activity do
    association :lead
    activity_type { :status_change }
    description { Faker::Lorem.sentence }
    performed_by { Faker::Name.name }
    previous_value { "new" }
    new_value { "contacted" }
    metadata { {} }

    trait :status_change do
      activity_type { :status_change }
      description { "Status changed" }
      previous_value { "new" }
      new_value { "contacted" }
    end

    trait :assignment_change do
      activity_type { :assignment_change }
      description { "Reassigned" }
      previous_value { "1" }
      new_value { "2" }
    end

    trait :note_added do
      activity_type { :note_added }
      description { Faker::Lorem.paragraph }
      previous_value { nil }
      new_value { nil }
    end

    trait :call_logged do
      activity_type { :call_logged }
      description { "Call logged" }
      previous_value { nil }
      new_value { nil }
      metadata { { duration: Faker::Number.between(from: 60, to: 3600), notes: Faker::Lorem.sentence } }
    end

    trait :email_sent do
      activity_type { :email_sent }
      description { "Email sent" }
      previous_value { nil }
      new_value { nil }
      metadata { { subject: Faker::Lorem.sentence, recipient: Faker::Internet.email } }
    end

    trait :old do
      created_at { 2.hours.ago }
    end

    trait :recent do
      created_at { 2.minutes.ago }
    end
  end
end
