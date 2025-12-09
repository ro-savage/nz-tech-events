class Event < ApplicationRecord
  belongs_to :user

  # Enums
  enum :event_type, {
    conference: 0,
    meetup: 1,
    workshop: 2,
    hackathon: 3,
    webinar: 4,
    networking: 5,
    other: 6
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
    online: 16
  }, prefix: true

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true
  validates :start_date, presence: true
  validates :event_type, presence: true
  validates :region, presence: true
  validates :city, presence: true

  validate :end_date_after_start_date, if: -> { end_date.present? }

  # Scopes
  scope :upcoming, -> { where("start_date >= ?", Date.current).order(start_date: :asc, start_time: :asc) }
  scope :past, -> { where("start_date < ?", Date.current).order(start_date: :desc, start_time: :desc) }
  scope :approved, -> { where(approved: true) }
  scope :pending_approval, -> { where(approved: false) }
  scope :by_region, ->(region) { where(region: region) if region.present? }
  scope :by_city, ->(city) { where(city: city) if city.present? }
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
    region.to_s.titleize.gsub("_", "-")
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
end
