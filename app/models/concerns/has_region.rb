module HasRegion
  extend ActiveSupport::Concern

  REGIONS = {
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
  }.freeze

  included do
    enum :region, REGIONS, prefix: true
  end

  def region_display
    return 'Asia Pacific' if region == 'apac'
    region.to_s.titleize.gsub('_', '-')
  end
end
