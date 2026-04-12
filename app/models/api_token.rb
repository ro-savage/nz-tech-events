class ApiToken < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validate :user_is_organiser_or_admin

  # Raw token is only available at creation time — never stored.
  def generate_token_value
    raw = "techevents_#{SecureRandom.base58(32)}"
    self.token_digest = Digest::SHA256.hexdigest(raw)
    raw
  end

  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    digest = Digest::SHA256.hexdigest(raw_token)
    find_by(token_digest: digest)
  end

  # Throttled to once per minute to reduce writes.
  def touch_last_used!
    return if last_used_at.present? && last_used_at > 1.minute.ago

    update_column(:last_used_at, Time.current)
  end

  private

  def user_is_organiser_or_admin
    return if user.blank?

    unless user.approved_organiser? || user.admin?
      errors.add(:user, "must be an approved organiser or admin")
    end
  end
end
