require 'rails_helper'

RSpec.describe Api::ActivitiesController, type: :request do
  let(:lead) { create(:lead) }
  let(:api_url) { "/api/leads/#{lead.id}/activities" }

  describe 'GET /api/leads/:lead_id/activities' do
    before do
      create(:activity, :status_change, lead: lead, created_at: 3.days.ago)
      create(:activity, :assignment_change, lead: lead, created_at: 2.days.ago)
      create(:activity, :note_added, lead: lead, created_at: 1.day.ago)
    end

    it 'returns all activities for the lead' do
      get api_url

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)

      expect(data['activities'].count).to eq(3)
    end

    it 'returns activities sorted by newest first' do
      get api_url

      data = JSON.parse(response.body)
      timestamps = data['activities'].map { |a| a['timestamp'] }

      expect(timestamps).to eq(timestamps.sort.reverse)
    end

    it 'returns properly formatted activity objects' do
      get api_url

      data = JSON.parse(response.body)
      activity = data['activities'].first

      expect(activity).to have_key('id')
      expect(activity).to have_key('type')
      expect(activity).to have_key('description')
      expect(activity).to have_key('performed_by')
      expect(activity).to have_key('timestamp')
      expect(activity).to have_key('changes')
    end

    it 'includes pagination metadata' do
      get api_url

      data = JSON.parse(response.body)

      expect(data['pagination']).to have_key('page')
      expect(data['pagination']).to have_key('total_pages')
    end

    context 'with activity_type filter' do
      it 'filters by activity_type' do
        get api_url, params: { activity_type: 'status_change' }

        data = JSON.parse(response.body)

        expect(data['activities'].count).to eq(1)
        expect(data['activities'].first['type']).to eq('status_change')
      end

      it 'returns empty array when no matching activities' do
        get api_url, params: { activity_type: 'call_logged' }

        data = JSON.parse(response.body)

        expect(data['activities'].count).to eq(0)
      end
    end

    context 'with date range filter' do
      it 'filters by start_date and end_date' do
        get api_url, params: {
          start_date: 2.days.ago.to_date,
          end_date: Time.current.to_date
        }

        data = JSON.parse(response.body)

        expect(data['activities'].count).to eq(2)
      end

      it 'returns empty array when date range has no activities' do
        get api_url, params: {
          start_date: 10.days.ago.to_date,
          end_date: 9.days.ago.to_date
        }

        data = JSON.parse(response.body)

        expect(data['activities'].count).to eq(0)
      end
    end

    context 'with pagination' do
      before do
        create_list(:activity, 15, lead: lead)
      end

      it 'returns paginated results with default page size 10' do
        get api_url

        data = JSON.parse(response.body)

        expect(data['activities'].count).to eq(10)
        expect(data['pagination']['page']).to eq(1)
      end

      it 'returns second page when requested' do
        get api_url, params: { page: 2 }

        data = JSON.parse(response.body)

        expect(data['activities'].count).to eq(8)
        expect(data['pagination']['page']).to eq(2)
      end

      it 'calculates total_pages correctly' do
        get api_url

        data = JSON.parse(response.body)

        expect(data['pagination']['total_pages']).to eq(2)
      end
    end

    it 'returns 404 when lead does not exist' do
      get "/api/leads/99999/activities"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/leads/:lead_id/activities' do
    let(:activity_params) do
      {
        activity_type: 'note_added',
        description: 'Test note'
      }
    end

    it 'creates a new activity' do
      expect {
        post api_url, params: activity_params
      }.to change(Activity, :count).by(1)
    end

    it 'returns the created activity' do
      post api_url, params: activity_params

      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)

      expect(data['type']).to eq('note_added')
      expect(data['description']).to eq('Test note')
      expect(data['performed_by']).to eq('System')
    end

    it 'sets performed_by to System' do
      post api_url, params: activity_params

      data = JSON.parse(response.body)

      expect(data['performed_by']).to eq('System')
    end

    context 'with metadata' do
      let(:params_with_metadata) do
        {
          activity_type: 'call_logged',
          description: 'Call logged',
          metadata: {
            duration: 300,
            notes: 'Discussed pricing'
          }
        }
      end

      it 'stores metadata as JSONB' do
        post api_url, params: params_with_metadata

        data = JSON.parse(response.body)

        expect(data).to have_key('id')
        activity = Activity.find(data['id'])
        # JSONB stores values as strings, so we compare as strings
        expect(activity.metadata['duration'].to_s).to eq('300')
        expect(activity.metadata['notes']).to eq('Discussed pricing')
      end
    end

    context 'with invalid params' do
      it 'fails without activity_type' do
        post api_url, params: { description: 'Test' }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it 'returns 404 when lead does not exist' do
      post "/api/leads/99999/activities", params: activity_params

      expect(response).to have_http_status(:not_found)
    end
  end
end
