xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.feed xmlns: "http://www.w3.org/2005/Atom" do
  xml.title "NZ Tech Events"
  xml.subtitle "Upcoming tech events across New Zealand"
  xml.link href: atom_feed_url(format: :atom), rel: "self", type: "application/atom+xml"
  xml.link href: root_url, rel: "alternate", type: "text/html"
  xml.id root_url
  xml.updated @events.first&.updated_at&.iso8601

  @events.each do |event|
    xml.entry do
      xml.title event.title
      xml.link href: event_url(event), rel: "alternate", type: "text/html"
      xml.id event_url(event)
      xml.published event.created_at.iso8601
      xml.updated event.updated_at.iso8601
      xml.summary event.display_summary
      xml.category term: event.event_type.humanize

      if event.location_regions_display.present?
        xml.author do
          xml.name event.location_regions_display
        end
      end
    end
  end
end
