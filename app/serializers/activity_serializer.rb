class ActivitySerializer
  def initialize(activity)
    @activity = activity
  end

  def as_json
    {
      id: @activity.id,
      type: @activity.activity_type,
      description: @activity.description,
      performed_by: @activity.performed_by,
      timestamp: @activity.created_at,
      changes: {
        from: @activity.previous_value,
        to: @activity.new_value
      }
    }
  end
end
