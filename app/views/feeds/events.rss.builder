xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "NZ Tech Events"
    xml.description "Upcoming tech events across New Zealand"
    xml.link root_url
    xml.language "en-nz"
    xml.lastBuildDate @events.first&.updated_at&.rfc2822
    xml.tag!("atom:link", href: feed_url(format: :rss), rel: "self", type: "application/rss+xml")

    @events.each do |event|
      xml.item do
        xml.title event.title
        xml.description event.display_summary
        xml.link event_url(event)
        xml.guid event_url(event), isPermaLink: "true"
        xml.pubDate event.created_at.rfc2822
        xml.category event.event_type.humanize

        if event.location_regions_display.present?
          xml.tag!("atom:author") do
            xml.name event.location_regions_display
          end
        end
      end
    end
  end
end
