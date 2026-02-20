class UndoStatusChangeService
  def initialize(lead)
    @lead = lead
  end

  def call
    last_activity = @lead.activities
                         .status_change
                         .where("created_at > ?", 5.minutes.ago)
                         .order(created_at: :desc)
                         .first

    return false unless last_activity

    @lead.update!(status: last_activity.previous_value)
    true
  end
end
