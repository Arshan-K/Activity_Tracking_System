class Api::LeadsController < ApplicationController
  before_action :set_lead

  # GET /api/leads/:id/activity-summary
  def activity_summary
    activities = @lead.activities

    render json: {
      counts: activities.group(:activity_type).count,
      last_activity_at: activities.maximum(:created_at),
      most_active_day: activities
                        .group("DATE(created_at)")
                        .order("count_all DESC")
                        .count
                        .first&.first
    }
  end

  def update
    old_status = @lead.status
    old_agent  = @lead.agent_id

    if @lead.update(lead_params)
        track_changes(old_status, old_agent)
        render json: @lead, status: :ok
    else
        render json: { errors: @lead.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/leads/:id/undo_status
  def undo_status
    result = UndoStatusChangeService.new(@lead).call

    if result
      render json: { message: "Undo successful" }
    else
      render json: { error: "Cannot undo" }, status: :unprocessable_content
    end
  end

  private

  def set_lead
    @lead = Lead.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(:status, :agent_id, :name, :email)
  end

  def track_changes(old_status, old_agent)
    # Status change
    if old_status != @lead.status
        Activity.create!(
        lead: @lead,
        activity_type: :status_change,
        description: "Status changed from '#{old_status}' to '#{@lead.status}'",
        previous_value: old_status,
        new_value: @lead.status,
        performed_by: "System"
        )
    end

    # Assignment change
    if old_agent != @lead.agent_id
        Activity.create!(
        lead: @lead,
        activity_type: :assignment_change,
        description: "Lead reassigned to agent #{@lead.agent_id}",
        previous_value: old_agent,
        new_value: @lead.agent_id,
        performed_by: "System"
        )
    end
  end
end
