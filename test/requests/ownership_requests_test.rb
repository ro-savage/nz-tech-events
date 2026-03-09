require "test_helper"

class OwnershipRequestsTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:approved_upcoming)
    @requester = users(:organiser)
  end

  test "GET /events/:event_id/ownership_requests/new redirects unauthenticated user" do
    get new_event_ownership_request_path(@event)

    assert_redirected_to new_session_path
  end

  test "GET /events/:event_id/ownership_requests/new returns 200 for logged-in non-owner" do
    sign_in_as @requester

    get new_event_ownership_request_path(@event)

    assert_response :success
  end

  test "GET /events/:event_id/ownership_requests/new redirects owner" do
    sign_in_as users(:regular)

    get new_event_ownership_request_path(@event)

    assert_redirected_to event_path(@event)
    follow_redirect!
    assert_match(/already own/i, flash[:alert])
  end

  test "POST /events/:event_id/ownership_requests creates pending request and enqueues admin notifications" do
    sign_in_as @requester
    admin_count = User.where(admin: true).count

    assert_difference "OwnershipRequest.count", 1 do
      assert_enqueued_emails admin_count do
        post event_ownership_requests_path(@event), params: {
          ownership_request: {
            reason: "I now coordinate this meetup.",
            requester_id: users(:regular).id,
            status: "approved"
          }
        }
      end
    end

    ownership_request = OwnershipRequest.order(:id).last

    assert_redirected_to event_path(@event)
    assert_equal @requester, ownership_request.requester
    assert ownership_request.pending?
    assert_nil ownership_request.reviewed_by
    assert_equal "I now coordinate this meetup.", ownership_request.reason
  end

  test "POST /events/:event_id/ownership_requests renders errors for blank reason" do
    sign_in_as @requester

    assert_no_difference "OwnershipRequest.count" do
      post event_ownership_requests_path(@event), params: {
        ownership_request: { reason: "   " }
      }
    end

    assert_response :unprocessable_entity
    assert_match(/reason can/i, response.body)
  end

  test "POST /events/:event_id/ownership_requests rejects duplicate pending request" do
    OwnershipRequest.create!(event: @event, requester: @requester, reason: "First request")
    sign_in_as @requester

    assert_no_difference "OwnershipRequest.count" do
      post event_ownership_requests_path(@event), params: {
        ownership_request: { reason: "Second request" }
      }
    end

    assert_redirected_to event_path(@event)
    follow_redirect!
    assert_match(/pending ownership request/i, flash[:alert])
  end

  test "POST /events/:event_id/ownership_requests redirects owner even with direct route access" do
    sign_in_as users(:regular)

    assert_no_difference "OwnershipRequest.count" do
      post event_ownership_requests_path(@event), params: {
        ownership_request: { reason: "Trying to request my own event" }
      }
    end

    assert_redirected_to event_path(@event)
    follow_redirect!
    assert_match(/already own/i, flash[:alert])
  end
end
