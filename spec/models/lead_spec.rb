require 'rails_helper'

RSpec.describe Lead, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:activities) }
  end

  describe 'traits from ActivityTrackable' do
    it { is_expected.to have_db_column(:status) }
    it { is_expected.to have_db_column(:agent_id) }
    it { is_expected.to have_db_column(:phone) }
    it { is_expected.to have_db_column(:email) }
    it { is_expected.to have_db_column(:budget) }
  end

  describe '#track_status_change' do
    let(:lead) { create(:lead, status: "new") }

    it 'creates an activity when status changes' do
      expect {
        lead.update(status: "contacted")
      }.to change(Activity, :count).by(1)
    end

    it 'records correct previous and new values' do
      lead.update(status: "contacted")
      activity = lead.activities.last

      expect(activity.activity_type).to eq("status_change")
      expect(activity.previous_value).to eq("new")
      expect(activity.new_value).to eq("contacted")
    end

    it 'creates activity when status does not change but other fields do' do
      expect {
        lead.update(phone: "1234567890")
      }.to change { Activity.where(activity_type: :field_change).count }.by(1)
    end
  end

  describe '#track_assignment_change' do
    let(:lead) { create(:lead, agent_id: 1) }

    it 'creates an activity when agent_id changes' do
      expect {
        lead.update(agent_id: 2)
      }.to change(Activity, :count).by(1)
    end

    it 'records correct assignment change' do
      lead.update(agent_id: 2)
      activity = lead.activities.last

      expect(activity.activity_type).to eq("assignment_change")
      expect(activity.previous_value).to eq("1")
      expect(activity.new_value).to eq("2")
    end

    it 'does not create activity if agent_id does not change' do
      expect {
        lead.update(status: "contacted")
      }.not_to change { Activity.where(activity_type: :assignment_change).count }
    end
  end

  describe '#track_important_changes' do
    let(:lead) { create(:lead, phone: "1111111111", email: "old@example.com", budget: 5000.00) }

    context 'when phone changes' do
      it 'creates an activity' do
        expect {
          lead.update(phone: "2222222222")
        }.to change(Activity, :count).by(1)
      end

      it 'records the phone change' do
        lead.update(phone: "2222222222")
        activity = lead.activities.last

        expect(activity.description).to include("phone updated")
        expect(activity.previous_value).to eq("1111111111")
        expect(activity.new_value).to eq("2222222222")
      end
    end

    context 'when email changes' do
      it 'creates an activity' do
        expect {
          lead.update(email: "new@example.com")
        }.to change(Activity, :count).by(1)
      end

      it 'records the email change' do
        lead.update(email: "new@example.com")
        activity = lead.activities.last

        expect(activity.description).to include("email updated")
        expect(activity.previous_value).to eq("old@example.com")
        expect(activity.new_value).to eq("new@example.com")
      end
    end

    context 'when budget changes' do
      it 'creates an activity' do
        expect {
          lead.update(budget: 10000.00)
        }.to change(Activity, :count).by(1)
      end

      it 'records the budget change' do
        lead.update(budget: 10000.00)
        activity = lead.activities.last

        expect(activity.description).to include("budget updated")
        expect(activity.previous_value).to eq("5000.0")
        expect(activity.new_value).to eq("10000.0")
      end
    end
  end

  describe 'multiple changes in single update' do
    let(:lead) { create(:lead, status: "new", agent_id: 1) }

    it 'creates multiple activities for multiple field changes' do
      expect {
        lead.update(status: "contacted", agent_id: 2)
      }.to change(Activity, :count).by(2)
    end
  end
end
