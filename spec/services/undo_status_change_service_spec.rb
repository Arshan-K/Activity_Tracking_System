require 'rails_helper'

RSpec.describe UndoStatusChangeService do
  let(:lead) { create(:lead, status: 'new') }
  let(:service) { described_class.new(lead) }

  describe '#call' do
    context 'when a recent status change exists' do
      before do
        lead.update!(status: 'contacted')
        @last_activity = Activity.find_by(activity_type: :status_change, new_value: 'contacted')
      end

      it 'reverts the status to previous value' do
        expect(lead.status).to eq('contacted')

        result = service.call

        expect(result).to be_truthy
        expect(lead.reload.status).to eq('new')
      end

      it 'returns true on successful undo' do
        result = service.call

        expect(result).to be_truthy
      end

      it 'creates a new activity record for the undo' do
        expect {
          service.call
        }.to change(Activity, :count).by(1)
      end

      context 'when activity is within 5 minute window' do
        it 'allows undo' do
          travel_to 4.minutes.from_now do
            result = service.call

            expect(result).to be_truthy
            expect(lead.reload.status).to eq('new')
          end
        end
      end

      context 'when activity is outside 5 minute window' do
        it 'returns false and does not undo' do
          travel_to 6.minutes.from_now do
            result = service.call

            expect(result).to be_falsey
            expect(lead.reload.status).to eq('contacted')
          end
        end
      end
    end

    context 'when no status change activity exists' do
      it 'returns false' do
        result = service.call

        expect(result).to be_falsey
      end

      it 'does not modify the lead status' do
        expect {
          service.call
        }.not_to change { lead.reload.status }
      end
    end

    context 'when multiple status changes exist' do
      before do
        lead.update!(status: 'contacted')
        travel_to 1.minute.from_now do
          lead.update!(status: 'qualified')
        end
      end

      it 'undoes only the most recent status change' do
        result = service.call

        expect(result).to be_truthy
        expect(lead.reload.status).to eq('contacted')
      end
    end

    context 'when status change is older than 5 minutes' do
      before do
        travel_to 10.minutes.ago do
          lead.update!(status: 'contacted')
        end
      end

      it 'returns false' do
        result = service.call

        expect(result).to be_falsey
      end

      it 'does not revert the status' do
        service.call

        expect(lead.reload.status).to eq('contacted')
      end
    end

    context 'with other activity types present' do
      before do
        lead.update!(status: 'contacted')
        create(:activity, :assignment_change, lead: lead)
        create(:activity, :note_added, lead: lead)
      end

      it 'only considers status_change activities' do
        result = service.call

        expect(result).to be_truthy
        expect(lead.reload.status).to eq('new')
      end
    end

    context 'when service is called multiple times' do
      before do
        lead.update!(status: 'contacted')
      end

      it 'only processes the first call, returns same result on second if within window' do
        first_call = service.call
        expect(first_call).to be_truthy
        expect(lead.reload.status).to eq('new')

        # Update status again to allow second undo
        lead.update!(status: 'contacted')
        second_call = service.call
        expect(second_call).to be_truthy
        expect(lead.reload.status).to eq('new')
      end
    end

    context 'edge case: status change exactly at 5 minute boundary' do
      before do
        lead.update!(status: 'contacted')
      end

      it 'allows undo at exactly 5 minutes' do
        travel_to 5.minutes.from_now do
          result = service.call

          expect(result).to be_truthy
          expect(lead.reload.status).to eq('new')
        end
      end
    end
  end
end
