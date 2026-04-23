module EventsHelper
  EVENT_TYPE_DROPDOWN_ORDER = %w[
    conference
    meetup
    talk
    networking
    workshop
    webinar
    hackathon
    awards
    other
  ].freeze

  CITIES_BY_REGION = {
    "northland" => [ "Whangarei", "Kerikeri", "Kaitaia", "Other" ],
    "auckland" => [ "Auckland CBD", "North Shore", "West Auckland", "South Auckland", "East Auckland", "Other" ],
    "waikato" => [ "Hamilton", "Cambridge", "Te Awamutu", "Other" ],
    "bay_of_plenty" => [ "Tauranga", "Rotorua", "Whakatane", "Other" ],
    "gisborne" => [ "Gisborne", "Other" ],
    "hawkes_bay" => [ "Napier", "Hastings", "Other" ],
    "taranaki" => [ "New Plymouth", "Hawera", "Other" ],
    "manawatu_whanganui" => [ "Palmerston North", "Whanganui", "Other" ],
    "wellington" => [ "Wellington CBD", "Lower Hutt", "Upper Hutt", "Porirua", "Kapiti Coast", "Other" ],
    "tasman" => [ "Richmond", "Motueka", "Other" ],
    "nelson" => [ "Nelson", "Other" ],
    "marlborough" => [ "Blenheim", "Other" ],
    "west_coast" => [ "Greymouth", "Hokitika", "Other" ],
    "canterbury" => [ "Christchurch", "Timaru", "Ashburton", "Other" ],
    "otago" => [ "Dunedin", "Queenstown", "Wanaka", "Other" ],
    "southland" => [ "Invercargill", "Gore", "Other" ],
    "apac" => [ "Sydney", "Melbourne", "Brisbane", "Singapore", "Kuala Lumpur", "Jakarta", "Bangkok", "Ho Chi Minh City", "Hanoi", "Manila", "Pacific Islands", "China", "Japan", "Other Australia", "Other APAC" ],
    "online" => [ "Online" ]
  }.freeze

  def cities_for_region(region)
    CITIES_BY_REGION[region.to_s] || []
  end

  def cities_json
    CITIES_BY_REGION.to_json.html_safe
  end

  def region_options
    Event.regions.keys.map do |r|
      label = r == "apac" ? "Asia Pacific" : r.titleize.gsub("_", "-")
      [ label, r ]
    end
  end

  def event_type_options
    keys = Event.event_types.keys
    known_ordered_keys = EVENT_TYPE_DROPDOWN_ORDER.select { |type| keys.include?(type) }
    unknown_keys = keys - EVENT_TYPE_DROPDOWN_ORDER
    ordered_keys = known_ordered_keys + unknown_keys

    ordered_keys.map { |type| [ type.titleize, type ] }
  end

  def month_filter_options
    (0..12).map do |i|
      date = Date.current + i.months
      [ date.strftime("%B %Y"), date.strftime("%Y-%m") ]
    end
  end

  def event_type_badge_class(event_type)
    "badge badge-#{event_type}"
  end

  # Schema.org event type mapping
  SCHEMA_ORG_EVENT_TYPES = {
    "conference" => "BusinessEvent",
    "meetup" => "SocialEvent",
    "workshop" => "EducationEvent",
    "hackathon" => "Hackathon",
    "webinar" => "EducationEvent",
    "networking" => "SocialEvent",
    "talk" => "EducationEvent",
    "awards" => "SocialEvent",
    "other" => "Event"
  }.freeze

  # JSON-LD structured data helpers

  # Generates a JSON-LD string for the Schema.org Event type.
  # Optional fields are omitted when the underlying data is not present.
  #
  # @param event [Event] the event to generate structured data for
  # @return [String] JSON-LD string safe for embedding in a script tag
  def event_json_ld(event)
    data = {
      "@context" => "https://schema.org",
      "@type" => schema_org_event_type(event),
      "name" => event.title,
      "startDate" => json_ld_start_date(event),
      "eventStatus" => "https://schema.org/EventScheduled"
    }

    description = event.display_summary
    data["description"] = description if description.present?

    attendance_mode = json_ld_attendance_mode(event)
    data["eventAttendanceMode"] = attendance_mode if attendance_mode

    end_date = json_ld_end_date(event)
    data["endDate"] = end_date if end_date

    location = json_ld_location(event)
    data["location"] = location if location

    data["url"] = event.registration_url if event.registration_url.present?

    offers = json_ld_offers(event)
    data["offers"] = offers if offers

    ERB::Util.json_escape(data.to_json).html_safe
  end

  # Calendar integration helpers
  NZ_TIMEZONE = "Pacific/Auckland"

  def google_calendar_url(event)
    start_time, end_time = calendar_times(event)

    params = {
      action: "TEMPLATE",
      text: event.title,
      dates: "#{format_google_time(start_time)}/#{format_google_time(end_time)}",
      details: event.description.to_plain_text.truncate(1000),
      location: calendar_location(event),
      ctz: NZ_TIMEZONE
    }

    "https://calendar.google.com/calendar/render?#{params.to_query}"
  end

  def ical_content(event)
    start_time, end_time = calendar_times(event)

    ical = []
    ical << "BEGIN:VCALENDAR"
    ical << "VERSION:2.0"
    ical << "PRODID:-//NZ Tech Events//techevents.co.nz//EN"
    ical << "CALSCALE:GREGORIAN"
    ical << "METHOD:PUBLISH"
    ical << "BEGIN:VTIMEZONE"
    ical << "TZID:Pacific/Auckland"
    ical << "END:VTIMEZONE"
    ical << "BEGIN:VEVENT"
    ical << "UID:event-#{event.id}@techevents.co.nz"
    ical << "DTSTAMP:#{format_ical_time(Time.current)}"
    ical << "DTSTART;TZID=Pacific/Auckland:#{format_ical_local_time(start_time)}"
    ical << "DTEND;TZID=Pacific/Auckland:#{format_ical_local_time(end_time)}"
    ical << "SUMMARY:#{escape_ical_text(event.title)}"
    ical << "DESCRIPTION:#{escape_ical_text(event.description.to_plain_text.truncate(1000))}"
    ical << "LOCATION:#{escape_ical_text(calendar_location(event))}"
    ical << "URL:#{event.registration_url}" if event.registration_url.present?
    ical << "END:VEVENT"
    ical << "END:VCALENDAR"

    ical.join("\r\n")
  end

  private

  # JSON-LD private helpers

  def schema_org_event_type(event)
    SCHEMA_ORG_EVENT_TYPES.fetch(event.event_type, "Event")
  end

  def json_ld_start_date(event)
    if event.start_time.present?
      format_json_ld_datetime(event.start_date, event.start_time)
    else
      event.start_date.iso8601
    end
  end

  def json_ld_end_date(event)
    if event.end_date.present? && event.end_date != event.start_date
      if event.end_time.present?
        format_json_ld_datetime(event.end_date, event.end_time)
      else
        event.end_date.iso8601
      end
    elsif event.end_time.present? && event.end_time != event.start_time
      format_json_ld_datetime(event.end_date || event.start_date, event.end_time)
    end
  end

  def format_json_ld_datetime(date, time)
    nz_zone = ActiveSupport::TimeZone[NZ_TIMEZONE]
    dt = nz_zone.local(date.year, date.month, date.day, time.hour, time.min)
    dt.iso8601
  end

  def json_ld_attendance_mode(event)
    primary = event.primary_location
    return nil unless primary

    if primary.region == "online"
      "https://schema.org/OnlineEventAttendanceMode"
    else
      "https://schema.org/OfflineEventAttendanceMode"
    end
  end

  def json_ld_location(event)
    primary = event.primary_location

    if primary&.region == "online"
      return nil unless event.registration_url.present?

      {
        "@type" => "VirtualLocation",
        "url" => event.registration_url
      }
    else
      place = { "@type" => "Place" }
      name_parts = [ primary&.city, primary&.region_display ].compact_blank
      place["name"] = name_parts.join(", ") if name_parts.any?

      if event.address.present?
        address = { "@type" => "PostalAddress", "streetAddress" => event.address }
        address["addressRegion"] = primary.region_display if primary
        address["addressCountry"] = "NZ"
        place["address"] = address
      end

      place.keys.size > 1 ? place : nil
    end
  end

  def json_ld_offers(event)
    price = event.free? ? "0" : parse_numeric_price(event.cost)
    return nil unless price

    offer = {
      "@type" => "Offer",
      "price" => price,
      "priceCurrency" => "NZD",
      "availability" => "https://schema.org/InStock"
    }
    offer["url"] = event.registration_url if event.registration_url.present?
    offer
  end

  # Extracts the first numeric value (with optional decimal) from a free-text
  # cost string. Returns nil if no number is present (e.g. "Koha", "TBC").
  def parse_numeric_price(cost)
    return nil if cost.blank?

    cost.to_s[/\d+(?:\.\d+)?/]
  end

  # Calendar private helpers

  def calendar_times(event)
    nz_zone = ActiveSupport::TimeZone[NZ_TIMEZONE]

    if event.start_time.present?
      start_time = nz_zone.local(
        event.start_date.year,
        event.start_date.month,
        event.start_date.day,
        event.start_time.hour,
        event.start_time.min
      )

      if event.end_time.present?
        end_date = event.end_date || event.start_date
        end_time = nz_zone.local(
          end_date.year,
          end_date.month,
          end_date.day,
          event.end_time.hour,
          event.end_time.min
        )
      else
        # Default to 2 hours if no end time
        end_time = start_time + 2.hours
      end
    else
      # All-day event
      start_time = nz_zone.local(event.start_date.year, event.start_date.month, event.start_date.day, 9, 0)
      end_date = event.end_date || event.start_date
      end_time = nz_zone.local(end_date.year, end_date.month, end_date.day, 17, 0)
    end

    [ start_time, end_time ]
  end

  def calendar_location(event)
    primary = event.primary_location
    parts = [ event.address, primary&.city, primary&.region_display ].compact_blank
    parts.join(", ")
  end

  def format_google_time(time)
    time.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def format_ical_time(time)
    time.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def format_ical_local_time(time)
    time.strftime("%Y%m%dT%H%M%S")
  end

  def escape_ical_text(text)
    return "" if text.blank?
    text.gsub("\\", "\\\\").gsub(",", "\\,").gsub(";", "\\;").gsub("\n", "\\n")
  end
end
