class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :events, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  # Name is required for OAuth users, optional for email users (they can set it later)
  validates :name, presence: true, if: :google_uid?

  # For display purposes
  def display_name
    name.presence || email_address.split('@').first
  end

  # Check if user signed up via Google
  def google_user?
    google_uid.present?
  end

  # Check if user is an admin
  def admin?
    admin == true
  end
end
