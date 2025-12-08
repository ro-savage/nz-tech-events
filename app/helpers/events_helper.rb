module EventsHelper
  CITIES_BY_REGION = {
    "northland" => ["Whangarei", "Kerikeri", "Kaitaia", "Other"],
    "auckland" => ["Auckland CBD", "North Shore", "West Auckland", "South Auckland", "East Auckland", "Other"],
    "waikato" => ["Hamilton", "Cambridge", "Te Awamutu", "Other"],
    "bay_of_plenty" => ["Tauranga", "Rotorua", "Whakatane", "Other"],
    "gisborne" => ["Gisborne", "Other"],
    "hawkes_bay" => ["Napier", "Hastings", "Other"],
    "taranaki" => ["New Plymouth", "Hawera", "Other"],
    "manawatu_whanganui" => ["Palmerston North", "Whanganui", "Other"],
    "wellington" => ["Wellington CBD", "Lower Hutt", "Upper Hutt", "Porirua", "Kapiti Coast", "Other"],
    "tasman" => ["Richmond", "Motueka", "Other"],
    "nelson" => ["Nelson", "Other"],
    "marlborough" => ["Blenheim", "Other"],
    "west_coast" => ["Greymouth", "Hokitika", "Other"],
    "canterbury" => ["Christchurch", "Timaru", "Ashburton", "Other"],
    "otago" => ["Dunedin", "Queenstown", "Wanaka", "Other"],
    "southland" => ["Invercargill", "Gore", "Other"],
    "online" => ["Online"]
  }.freeze

  def cities_for_region(region)
    CITIES_BY_REGION[region.to_s] || []
  end

  def cities_json
    CITIES_BY_REGION.to_json.html_safe
  end

  def region_options
    Event.regions.keys.map { |r| [r.titleize.gsub("_", "-"), r] }
  end

  def event_type_options
    Event.event_types.keys.map { |t| [t.titleize, t] }
  end

  def event_type_badge_class(event_type)
    "badge badge-#{event_type}"
  end
end
