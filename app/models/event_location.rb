class EventLocation < ApplicationRecord
  belongs_to :event, touch: true

  enum :region, {
    northland: 0,
    auckland: 1,
    waikato: 2,
    bay_of_plenty: 3,
    gisborne: 4,
    hawkes_bay: 5,
    taranaki: 6,
    manawatu_whanganui: 7,
    wellington: 8,
    tasman: 9,
    nelson: 10,
    marlborough: 11,
    west_coast: 12,
    canterbury: 13,
    otago: 14,
    southland: 15,
    apac: 16,
    online: 17
  }, prefix: true

  validates :region, presence: true

  default_scope { order(position: :asc) }

  def region_display
    return "Asia Pacific" if region == "apac"
    region.to_s.titleize.gsub("_", "-")
  end

  def full_display
    city.present? ? "#{city}, #{region_display}" : region_display
  end
end
