class EmailSubscription < ApplicationRecord
  include HasRegion

  validates :email_address, presence: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :region, presence: true
  validates :email_address, uniqueness: { scope: :region, message: "is already subscribed to this region" }

  before_create :generate_unsubscribe_token

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
