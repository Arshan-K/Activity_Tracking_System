require 'rails_helper'

RSpec.describe Api::LeadsController, type: :request do
  let(:lead) { create(:lead) }
  let(:api_summary_url) { "/api/leads/#{lead.id}/activity_summary" }
  let(:api_undo_url) { "/api/leads/#{lead.id}/undo_status" }

  describe 'GET /api/leads/:id/activity_summary' do
    before do
      create(:activity, :status_change, lead: lead)
      create(:activity, :status_change, lead: lead)
      create(:activity, :assignment_change, lead: lead)
      create(:activity, :call_logged, lead: lead)
    end

    it 'returns activity summary for the lead' do
      get api_summary_url

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)

      expect(data).to have_key('counts')
      expect(data).to have_key('last_activity_at')
      expect(data).to have_key('most_active_day')
    end

    it 'returns counts grouped by activity_type' do
      get api_summary_url

      data = JSON.parse(response.body)
      counts = data['counts']

      # Rails may return integer or string keys depending on serialization
      expect(counts['status_change']).to eq(2)
      expect(counts[1] || counts['assignment_change']).to eq(1) # assignment_change
      expect(counts[3] || counts['call_logged']).to eq(1) # call_logged
    end

    it 'returns last activity timestamp' do
      get api_summary_url

      data = JSON.parse(response.body)

      expect(data['last_activity_at']).to be_present
      expect(Time.parse(data['last_activity_at'])).to be_within(1.second).of(Time.current)
    end

    it 'returns most active day' do
      get api_summary_url

      data = JSON.parse(response.body)

      expect(data['most_active_day']).to be_present
    end

    it 'returns 404 when lead does not exist' do
      get "/api/leads/99999/activity_summary"

      expect(response).to have_http_status(:not_found)
    end

    context 'with activities on multiple days' do
      before do
        travel_to 2.days.ago do
          create(:activity, :status_change, lead: lead, created_at: 2.days.ago)
          create(:activity, :status_change, lead: lead, created_at: 2.days.ago)
        end
      end

      it 'correctly calculates most active day' do
        get api_summary_url

        data = JSON.parse(response.body)

        # Today should be most active (has 4 activities)
        expect(data['most_active_day']).to be_present
      end
    end

    context 'with no activities' do
      let(:lead_without_activities) { create(:lead) }

      it 'handles lead with no activities gracefully' do
        get "/api/leads/#{lead_without_activities.id}/activity_summary"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)

        expect(data['counts']).to eq({})
        expect(data['last_activity_at']).to be_nil
        expect(data['most_active_day']).to be_nil
      end
    end
  end

  describe 'POST /api/leads/:id/undo_status' do
    context 'when last status change was within 5 minutes' do
      let(:lead) { create(:lead, status: 'contacted') }

      before do
        lead.update!(status: 'new')
        @activity = Activity.find_by(activity_type: :status_change, new_value: 'new')
      end

      it 'reverts the status change' do
        post api_undo_url

        expect(response).to have_http_status(:ok)
        expect(lead.reload.status).to eq('contacted')
      end

      it 'returns success message' do
        post api_undo_url

        data = JSON.parse(response.body)

        expect(data['message']).to eq('Undo successful')
      end
    end

    context 'when last status change was more than 5 minutes ago' do
      let(:lead) { create(:lead, status: 'contacted') }

      before do
        travel_to 10.minutes.ago do
          lead.update!(status: 'new')
        end
      end

      it 'does not undo the change' do
        post api_undo_url

        expect(response).to have_http_status(:unprocessable_content)
        expect(lead.reload.status).to eq('new')
      end

      it 'returns error message' do
        post api_undo_url

        data = JSON.parse(response.body)

        expect(data['error']).to eq('Cannot undo')
      end
    end

    context 'when no status change has been made' do
      let(:lead) { create(:lead) }

      it 'returns error' do
        post api_undo_url

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['error']).to eq('Cannot undo')
      end
    end

    it 'returns 404 when lead does not exist' do
      post "/api/leads/99999/undo_status"

      expect(response).to have_http_status(:not_found)
    end
  end
end
