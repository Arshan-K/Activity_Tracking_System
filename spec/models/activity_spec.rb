require 'rails_helper'

RSpec.describe Activity, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:lead) }
  end

  describe 'enum activity_type' do
    it { is_expected.to define_enum_for(:activity_type).with_values(status_change: 0, assignment_change: 1, note_added: 2, call_logged: 3, email_sent: 4, field_change: 5) }
  end

  describe 'validations' do
    it 'validates lead must exist' do
      activity = build(:activity, lead: nil)
      expect(activity).not_to be_valid
      expect(activity.errors[:lead]).to include("must exist")
    end
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:lead_id).of_type(:integer) }
    it { is_expected.to have_db_column(:activity_type).of_type(:integer) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:performed_by).of_type(:string) }
    it { is_expected.to have_db_column(:previous_value).of_type(:string) }
    it { is_expected.to have_db_column(:new_value).of_type(:string) }
    it { is_expected.to have_db_column(:metadata).of_type(:jsonb) }
  end

  describe 'factory' do
    it 'creates a valid activity' do
      activity = build(:activity, lead: create(:lead))
      expect(activity).to be_valid
    end

    it 'creates status_change activity' do
      activity = build(:activity, :status_change)
      expect(activity.activity_type).to eq("status_change")
    end

    it 'creates call_logged activity with metadata' do
      activity = build(:activity, :call_logged)
      expect(activity.activity_type).to eq("call_logged")
      expect(activity.metadata).to include("duration", "notes")
    end

    it 'creates email_sent activity with metadata' do
      activity = build(:activity, :email_sent)
      expect(activity.activity_type).to eq("email_sent")
      expect(activity.metadata).to include("subject", "recipient")
    end
  end

  describe 'scopes' do
    let(:lead) { create(:lead) }

    before do
      create(:activity, lead: lead, activity_type: :status_change)
      create(:activity, lead: lead, activity_type: :note_added)
      create(:activity, lead: lead, activity_type: :call_logged)
    end

    it 'can filter by activity_type using enum' do
      status_change_activities = Activity.where(activity_type: :status_change)
      expect(status_change_activities.count).to eq(1)
      expect(status_change_activities.first.activity_type).to eq("status_change")
    end

    it 'can order by created_at' do
      activities = Activity.order(created_at: :desc)
      expect(activities.first.created_at).to be >= activities.last.created_at
    end

    it 'can filter by date range' do
      lead.activities.create!(activity_type: :status_change, description: "Old activity", created_at: 10.days.ago)
      recent = Activity.where(created_at: 1.day.ago..Time.current)

      expect(recent.count).to eq(3)
    end
  end

  describe 'JSONB metadata' do
    let(:activity) { create(:activity, metadata: { key: "value", nested: { deep_key: "deep_value" } }) }

    it 'stores and retrieves JSONB data' do
      expect(activity.metadata["key"]).to eq("value")
      expect(activity.metadata["nested"]["deep_key"]).to eq("deep_value")
    end

    it 'persists correctly to database' do
      activity.save!
      reloaded = Activity.find(activity.id)
      expect(reloaded.metadata).to eq({ "key" => "value", "nested" => { "deep_key" => "deep_value" } })
    end
  end

  describe 'timestamps' do
    let(:activity) { create(:activity) }

    it 'sets created_at on creation' do
      expect(activity.created_at).to be_present
    end

    it 'sets updated_at on creation' do
      expect(activity.updated_at).to be_present
    end
  end
end
