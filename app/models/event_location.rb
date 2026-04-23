class EventLocation < ApplicationRecord
  include HasRegion

  belongs_to :event, touch: true

  validates :region, presence: true

  default_scope { order(position: :asc) }

  def full_display
    city.present? ? "#{city}, #{region_display}" : region_display
  end
end
