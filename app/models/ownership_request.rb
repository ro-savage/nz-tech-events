class OwnershipRequest < ApplicationRecord
  belongs_to :event
  belongs_to :requester, class_name: "User", inverse_of: :ownership_requests
  belongs_to :reviewed_by, class_name: "User", optional: true, inverse_of: :reviewed_ownership_requests

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :reason, presence: true
  validates :requester_id,
            uniqueness: {
              scope: :event_id,
              conditions: -> { pending },
              message: "already has a pending request for this event"
            }
  validate :requester_is_not_current_owner

  scope :recent_first, -> { order(created_at: :desc) }
  scope :pending_first, -> { pending.recent_first }

  def approve!(admin_user)
    ensure_admin!(admin_user)

    transaction do
      reload
      ensure_pending!

      reviewed_at = Time.current

      ensure_requester_can_take_ownership!
      update!(status: :approved, reviewed_by: admin_user, reviewed_at: reviewed_at)
      event.update!(user: requester)
      reject_other_pending_requests!(admin_user, reviewed_at)
    end
  end

  def reject!(admin_user)
    ensure_admin!(admin_user)

    transaction do
      reload
      ensure_pending!
      update!(status: :rejected, reviewed_by: admin_user, reviewed_at: Time.current)
    end
  end

  private

  def ensure_admin!(admin_user)
    return if admin_user&.admin?

    errors.add(:base, "Only admins can review ownership requests")
    raise ActiveRecord::RecordInvalid.new(self)
  end

  def ensure_requester_can_take_ownership!
    event.reload
    return unless event.owned_by?(requester)

    errors.add(:requester, "already owns this event")
    raise ActiveRecord::RecordInvalid.new(self)
  end

  def ensure_pending!
    return if pending?

    errors.add(:base, "Ownership request has already been reviewed")
    raise ActiveRecord::RecordInvalid.new(self)
  end

  def requester_is_not_current_owner
    return if event.blank? || requester.blank?
    return unless event.owned_by?(requester)

    errors.add(:requester, "already owns this event")
  end

  def reject_other_pending_requests!(admin_user, reviewed_at)
    event.ownership_requests.pending.where.not(id: id).update_all(
      status: self.class.statuses[:rejected],
      reviewed_by_id: admin_user.id,
      reviewed_at: reviewed_at,
      updated_at: reviewed_at
    )
  end
end
