class Lead < ApplicationRecord
  include ActivityTrackable
  has_many :activities
end
