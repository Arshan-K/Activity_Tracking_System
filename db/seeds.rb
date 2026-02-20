require 'faker'

# Clear existing data
puts "Clearing existing data..."
Activity.delete_all
Lead.delete_all

puts "Creating seed data..."

# Create leads with various statuses
STATUSES = [ 'new', 'contacted', 'qualified', 'won', 'lost' ].freeze
AGENT_IDS = (1..10).to_a.freeze

# Create 20 leads
20.times do |i|
  lead = Lead.create!(
    name: Faker::Name.name,
    status: STATUSES.sample,
    phone: Faker::PhoneNumber.phone_number,
    email: Faker::Internet.email,
    budget: Faker::Number.decimal(l_digits: 5, r_digits: 2),
    agent_id: AGENT_IDS.sample
  )

  puts "Created lead: #{lead.name} (#{lead.id})"
end

# Create activities for each lead with realistic data
puts "\nCreating activities..."

Lead.find_each do |lead|
  # Create 5-15 activities per lead
  rand(5..15).times do
    activity_type = Activity.activity_types.keys.sample

    case activity_type
    when 'status_change'
      from_status = STATUSES.sample
      to_status = STATUSES.sample
      until from_status != to_status
        to_status = STATUSES.sample
      end

      Activity.create!(
        lead: lead,
        activity_type: :status_change,
        description: "Status changed from '#{from_status}' to '#{to_status}'",
        performed_by: Faker::Name.name,
        previous_value: from_status,
        new_value: to_status,
        metadata: {},
        created_at: Faker::Time.backward(days: 30)
      )

    when 'assignment_change'
      old_agent = AGENT_IDS.sample
      new_agent = AGENT_IDS.sample
      until old_agent != new_agent
        new_agent = AGENT_IDS.sample
      end

      Activity.create!(
        lead: lead,
        activity_type: :assignment_change,
        description: "Lead reassigned to agent #{new_agent}",
        performed_by: Faker::Name.name,
        previous_value: old_agent.to_s,
        new_value: new_agent.to_s,
        metadata: {},
        created_at: Faker::Time.backward(days: 30)
      )

    when 'note_added'
      Activity.create!(
        lead: lead,
        activity_type: :note_added,
        description: Faker::Lorem.paragraph(sentence_count: 2),
        performed_by: Faker::Name.name,
        previous_value: nil,
        new_value: nil,
        metadata: {},
        created_at: Faker::Time.backward(days: 30)
      )

    when 'call_logged'
      Activity.create!(
        lead: lead,
        activity_type: :call_logged,
        description: "Call logged with #{lead.name}",
        performed_by: Faker::Name.name,
        previous_value: nil,
        new_value: nil,
        metadata: {
          duration: rand(60..3600),
          notes: Faker::Lorem.sentence,
          sentiment: [ 'positive', 'neutral', 'negative' ].sample
        },
        created_at: Faker::Time.backward(days: 30)
      )

    when 'email_sent'
      Activity.create!(
        lead: lead,
        activity_type: :email_sent,
        description: "Email sent to #{lead.email}",
        performed_by: Faker::Name.name,
        previous_value: nil,
        new_value: nil,
        metadata: {
          subject: Faker::Lorem.sentence(word_count: 5),
          recipient: lead.email,
          template: [ 'follow_up', 'proposal', 'inquiry', 'payment_reminder' ].sample,
          opened: [ true, false ].sample,
          clicked: [ true, false ].sample
        },
        created_at: Faker::Time.backward(days: 30)
      )
    end
  end
end

puts "\nSeed data created successfully!"
puts "Total leads: #{Lead.count}"
puts "Total activities: #{Activity.count}"

# Print summary
puts "\n=== Activity Type Summary ==="
Activity.group(:activity_type).count.each do |type, count|
  puts "#{type}: #{count}"
end

puts "\n=== Lead Status Summary ==="
Lead.group(:status).count.each do |status, count|
  puts "#{status}: #{count}"
end

puts "\n=== Activity Timeline Sample ==="
puts "Recent activities for first lead:"
Lead.first.activities.order(created_at: :desc).limit(5).each do |activity|
  puts "- #{activity.activity_type}: #{activity.description} (#{activity.created_at.strftime('%Y-%m-%d %H:%M:%S')})"
end
