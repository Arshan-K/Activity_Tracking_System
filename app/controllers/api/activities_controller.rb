# app/controllers/api/activities_controller.rb

class Api::ActivitiesController < ApplicationController
  before_action :set_lead

  # GET /api/leads/:lead_id/activities
  def index
    activities = @lead.activities.order(created_at: :desc)

    # filter by type
    if params[:activity_type].present?
      activities = activities.where(activity_type: params[:activity_type])
    end

    # filter by date range
    if params[:start_date].present? && params[:end_date].present?
      activities = activities.where(created_at: params[:start_date]..params[:end_date])
    end

    activities = activities.page(params[:page]).per(5)

    render json: {
      activities: activities.map { |a| ActivitySerializer.new(a).as_json },
      pagination: {
        page: activities.current_page,
        total_pages: activities.total_pages
      }
    }
  end

  # POST /api/leads/:lead_id/activities
  def create
    activity = @lead.activities.build(
      activity_params.merge(performed_by: "System")
    )

    if activity.save
      render json: ActivitySerializer.new(activity).as_json, status: :created
    else
      render json: { errors: activity.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_lead
    @lead = Lead.find(params[:lead_id])
  end

  def activity_params
    params.permit(:activity_type, :description, metadata: {})
  end
end
