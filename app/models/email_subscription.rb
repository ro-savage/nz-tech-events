class EmailSubscription < ApplicationRecord
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

  validates :email_address, presence: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :region, presence: true
  validates :email_address, uniqueness: { scope: :region, message: "is already subscribed to this region" }

  before_create :generate_unsubscribe_token

  def region_display
    return "Asia Pacific" if region == "apac"
    region.to_s.titleize.gsub("_", "-")
  end

  def mark_sent!
    update!(last_sent_at: Time.current)
  end

  def events_cutoff_date
    7.days.ago.to_date
  end

  private

  def generate_unsubscribe_token
    self.unsubscribe_token = SecureRandom.urlsafe_base64(32)
  end
end
