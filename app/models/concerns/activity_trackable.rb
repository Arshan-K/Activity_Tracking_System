# app/models/concerns/activity_trackable.rb
module ActivityTrackable
  extend ActiveSupport::Concern

  included do
    after_update :track_status_change
    after_update :track_assignment_change
    after_update :track_important_changes
  end

  private

  def track_status_change
    return unless saved_change_to_status?

    Activity.create!(
      lead: self,
      activity_type: :status_change,
      description: "Status changed from '#{status_before_last_save}' to '#{status}'",
      previous_value: status_before_last_save,
      new_value: status,
      performed_by: (Current.user&.name if defined?(Current)) || "System"
    )
  end

  def track_assignment_change
    return unless saved_change_to_agent_id?

    Activity.create!(
      lead: self,
      activity_type: :assignment_change,
      description: "Reassigned",
      previous_value: agent_id_before_last_save.to_s,
      new_value: agent_id.to_s,
      performed_by: (Current.user&.name if defined?(Current)) || "System"
    )
  end

  def track_important_changes
    important_fields = %w[phone email budget]

    important_fields.each do |field|
      if saved_change_to_attribute?(field)
        Activity.create!(
          lead: self,
          activity_type: :field_change,
          description: "#{field} updated",
          previous_value: saved_change_to_attribute(field)[0].to_s,
          new_value: saved_change_to_attribute(field)[1].to_s,
          performed_by: (Current.user&.name if defined?(Current)) || "System"
        )
      end
    end
  end
end
