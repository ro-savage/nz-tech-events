class MigrateDescriptionsToActionText < ActiveRecord::Migration[8.1]
  def up
    Event.find_each do |event|
      old_text = event.read_attribute(:description)
      next if old_text.blank?

      # Preserve paragraph breaks as Trix-compatible HTML
      html = old_text.split(/\n{2,}/).map { |p|
        "<div>#{ERB::Util.html_escape(p.strip.gsub("\n", "<br>"))}</div>"
      }.join

      ActionText::RichText.create!(
        record_type: "Event",
        record_id: event.id,
        name: "description",
        body: html
      )
    end

    remove_column :events, :description
  end

  def down
    add_column :events, :description, :text
    ActionText::RichText.where(record_type: "Event", name: "description").find_each do |rt|
      Event.where(id: rt.record_id).update_all(description: rt.body.to_plain_text)
    end
  end
end
