require "test_helper"

class OwnershipRequestTest < ActiveSupport::TestCase
  test "valid ownership request with event requester and reason" do
    ownership_request = OwnershipRequest.new(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "I now organise this meetup."
    )

    assert ownership_request.valid?
  end

  test "reason is required" do
    ownership_request = OwnershipRequest.new(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "   "
    )

    assert_not ownership_request.valid?
    assert_includes ownership_request.errors[:reason], "can't be blank"
  end

  test "requester cannot already own the event" do
    ownership_request = OwnershipRequest.new(
      event: events(:approved_upcoming),
      requester: users(:regular),
      reason: "I already manage it."
    )

    assert_not ownership_request.valid?
    assert_includes ownership_request.errors[:requester], "already owns this event"
  end

  test "same requester cannot have two pending requests for the same event" do
    OwnershipRequest.create!(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "First request"
    )

    duplicate = OwnershipRequest.new(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "Second request"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:requester_id], "already has a pending request for this event"
  end

  test "same requester can submit a new request after the previous one was rejected" do
    OwnershipRequest.create!(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "Old request",
      status: :rejected,
      reviewed_by: users(:admin),
      reviewed_at: Time.current
    )

    ownership_request = OwnershipRequest.new(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "New request"
    )

    assert ownership_request.valid?
  end

  test "approve transfers ownership and rejects competing pending requests" do
    event = events(:paid_event)
    approved_request = OwnershipRequest.create!(
      event: event,
      requester: users(:regular),
      reason: "I now organise this conference."
    )
    competing_request = OwnershipRequest.create!(
      event: event,
      requester: users(:admin),
      reason: "I am helping to run this conference."
    )

    approved_request.approve!(users(:admin))

    approved_request.reload
    competing_request.reload
    event.reload

    assert approved_request.approved?
    assert_equal users(:admin), approved_request.reviewed_by
    assert_not_nil approved_request.reviewed_at
    assert competing_request.rejected?
    assert_equal users(:admin), competing_request.reviewed_by
    assert_equal users(:regular), event.user
  end

  test "reject marks request as reviewed" do
    ownership_request = OwnershipRequest.create!(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "Please transfer this event to me."
    )

    ownership_request.reject!(users(:admin))
    ownership_request.reload

    assert ownership_request.rejected?
    assert_equal users(:admin), ownership_request.reviewed_by
    assert_not_nil ownership_request.reviewed_at
  end

  test "non-admin cannot approve a request" do
    event = events(:approved_upcoming)
    ownership_request = OwnershipRequest.create!(
      event: event,
      requester: users(:organiser),
      reason: "Please transfer this event to me."
    )

    error = assert_raises(ActiveRecord::RecordInvalid) do
      ownership_request.approve!(users(:regular))
    end

    ownership_request.reload
    event.reload

    assert_match(/only admins/i, error.record.errors.full_messages.to_sentence)
    assert ownership_request.pending?
    assert_equal users(:regular), event.user
  end

  test "request cannot be reviewed twice" do
    ownership_request = OwnershipRequest.create!(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "Please transfer this event to me."
    )
    ownership_request.reject!(users(:admin))

    error = assert_raises(ActiveRecord::RecordInvalid) do
      ownership_request.reject!(users(:admin))
    end

    assert_match(/already been reviewed/i, error.record.errors.full_messages.to_sentence)
  end
end
