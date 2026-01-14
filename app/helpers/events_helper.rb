module EventsHelper
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
    Event.event_types.keys.map { |t| [ t.titleize, t ] }
  end

  def month_filter_options
    (0..12).map do |i|
      date = Date.current + i.months
      [date.strftime("%B %Y"), date.strftime("%Y-%m")]
    end
  end

  def event_type_badge_class(event_type)
    "badge badge-#{event_type}"
  end

  # Calendar integration helpers
  NZ_TIMEZONE = "Pacific/Auckland"

  def google_calendar_url(event)
    start_time, end_time = calendar_times(event)

    params = {
      action: "TEMPLATE",
      text: event.title,
      dates: "#{format_google_time(start_time)}/#{format_google_time(end_time)}",
      details: event.description.truncate(1000),
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
    ical << "DESCRIPTION:#{escape_ical_text(event.description.truncate(1000))}"
    ical << "LOCATION:#{escape_ical_text(calendar_location(event))}"
    ical << "URL:#{event.registration_url}" if event.registration_url.present?
    ical << "END:VEVENT"
    ical << "END:VCALENDAR"

    ical.join("\r\n")
  end

  private

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
