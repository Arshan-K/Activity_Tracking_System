class Activity < ApplicationRecord
  belongs_to :lead

  validates :activity_type, presence: true
  validates :lead_id, presence: true
  validate :lead_must_exist

  enum :activity_type, {
    status_change: 0,
    assignment_change: 1,
    note_added: 2,
    call_logged: 3,
    email_sent: 4,
    field_change: 5
  }

  private

  def lead_must_exist
    errors.add(:lead, "must exist") if lead.nil?
  end
end
