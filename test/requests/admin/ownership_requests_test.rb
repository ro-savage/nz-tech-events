require "test_helper"

class Admin::OwnershipRequestsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @regular = users(:regular)
    @requester = users(:organiser)
    @event = events(:approved_upcoming)
    @ownership_request = OwnershipRequest.create!(
      event: @event,
      requester: @requester,
      reason: "I now run this meetup."
    )
  end

  test "GET /admin/ownership_requests redirects unauthenticated user" do
    get admin_ownership_requests_path

    assert_redirected_to new_session_path
  end

  test "GET /admin/ownership_requests redirects non-admin user" do
    sign_in_as @regular

    get admin_ownership_requests_path

    assert_redirected_to root_path
  end

  test "GET /admin/ownership_requests returns 200 for admin" do
    sign_in_as @admin

    get admin_ownership_requests_path

    assert_response :success
    assert_match @ownership_request.reason, response.body
  end

  test "POST /admin/ownership_requests/:id/approve transfers ownership and rejects competing requests" do
    competing_request = OwnershipRequest.create!(
      event: @event,
      requester: @admin,
      reason: "I also help manage this event."
    )
    sign_in_as @admin

    assert_enqueued_emails 1 do
      post approve_admin_ownership_request_path(@ownership_request)
    end

    @ownership_request.reload
    competing_request.reload
    @event.reload

    assert_redirected_to admin_ownership_requests_path
    assert @ownership_request.approved?
    assert_equal @admin, @ownership_request.reviewed_by
    assert competing_request.rejected?
    assert_equal @requester, @event.user
  end

  test "POST /admin/ownership_requests/:id/approve redirects non-admin user" do
    sign_in_as @regular

    post approve_admin_ownership_request_path(@ownership_request)

    @ownership_request.reload
    @event.reload

    assert_redirected_to root_path
    assert @ownership_request.pending?
    assert_equal @regular, @event.user
  end

  test "POST /admin/ownership_requests/:id/reject marks request rejected for admin" do
    sign_in_as @admin

    post reject_admin_ownership_request_path(@ownership_request)

    @ownership_request.reload

    assert_redirected_to admin_ownership_requests_path
    assert @ownership_request.rejected?
    assert_equal @admin, @ownership_request.reviewed_by
    assert_not_nil @ownership_request.reviewed_at
  end

  test "POST /admin/ownership_requests/:id/reject redirects non-admin user" do
    sign_in_as @regular

    post reject_admin_ownership_request_path(@ownership_request)

    @ownership_request.reload

    assert_redirected_to root_path
    assert @ownership_request.pending?
  end
end
