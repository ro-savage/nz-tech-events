class Event < ApplicationRecord
  belongs_to :user
  has_many :event_locations, dependent: :destroy
  accepts_nested_attributes_for :event_locations, allow_destroy: true,
                                reject_if: proc { |attrs| attrs["region"].blank? }

  # Enums
  enum :event_type, {
    conference: 0,
    meetup: 1,
    workshop: 2,
    hackathon: 3,
    webinar: 4,
    networking: 5,
    other: 6,
    talk: 7,
    awards: 8
  }, prefix: true

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

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true
  validates :start_date, presence: true
  validates :event_type, presence: true

  validate :end_date_after_start_date, if: -> { end_date.present? }
  validate :at_least_one_location
  validate :user_within_rate_limit, on: :create

  # Scopes
  scope :upcoming, -> { where("start_date >= ?", Date.current).order(start_date: :asc, start_time: :asc) }
  scope :past, -> { where("start_date < ?", Date.current).order(start_date: :desc, start_time: :desc) }
  scope :approved, -> { where(approved: true) }
  scope :pending_approval, -> { where(approved: false) }
  scope :by_region, ->(region) {
    return all if region.blank?
    joins(:event_locations)
      .where(event_locations: { region: EventLocation.regions[region] })
      .distinct
  }
  scope :by_city, ->(city) {
    return all if city.blank?
    joins(:event_locations)
      .where(event_locations: { city: city })
      .distinct
  }
  scope :by_event_type, ->(type) { where(event_type: type) if type.present? }

  # Callbacks
  before_create :set_approval_status

  # Instance methods
  def owned_by?(check_user)
    user_id == check_user&.id
  end

  def editable_by?(check_user)
    return false unless check_user
    check_user.admin? || owned_by?(check_user)
  end

  def multi_day?
    end_date.present? && end_date != start_date
  end

  def free?
    cost.blank? || cost.downcase.include?("free")
  end

  def formatted_date
    if multi_day?
      "#{start_date.strftime('%d %b')} - #{end_date.strftime('%d %b %Y')}"
    else
      start_date.strftime("%A, %d %B %Y")
    end
  end

  def formatted_time
    return nil unless start_time

    if end_time && end_time != start_time
      "#{start_time.strftime('%l:%M %p').strip} - #{end_time.strftime('%l:%M %p').strip}"
    else
      start_time.strftime("%l:%M %p").strip
    end
  end

  def region_display
    return "Asia Pacific" if region == "apac"
    region.to_s.titleize.gsub("_", "-")
  end

  # Multi-location helpers
  def primary_location
    event_locations.first
  end

  def location_regions
    event_locations.map(&:region_display).uniq
  end

  def location_regions_display
    location_regions.join(", ")
  end

  def locations_tooltip
    event_locations.map(&:full_display).join("\n")
  end

  def multi_location?
    event_locations.size > 1
  end

  # For data attributes on card (filtering)
  def location_region_keys
    event_locations.map(&:region).join(",")
  end

  def location_city_values
    event_locations.map(&:city).compact.join(",")
  end

  def display_summary(limit: 500)
    if short_summary.present?
      short_summary
    else
      description.truncate(limit)
    end
  end

  private

  def set_approval_status
    # Auto-approve if user is an approved organiser or admin
    self.approved = user&.approved_organiser? || user&.admin?
  end

  def end_date_after_start_date
    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def at_least_one_location
    valid_locations = event_locations.reject(&:marked_for_destruction?)
    if valid_locations.empty?
      errors.add(:base, "At least one location is required")
    end
  end

  def user_within_rate_limit
    return if user.blank?
    return if user.admin? || user.approved_organiser?

    if user.events_created_in_last_24_hours >= 10
      errors.add(:base, "You can only create 10 events in a 24-hour period. Please try again later.")
    end
  end
end
