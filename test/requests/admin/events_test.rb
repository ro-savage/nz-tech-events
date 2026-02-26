require "test_helper"

class Admin::EventsRequestTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @regular = users(:regular)
    @unapproved_event = events(:unapproved_upcoming)
  end

  # GET /admin/events/pending

  test "GET /admin/events/pending redirects unauthenticated user" do
    get admin_pending_events_path
    assert_redirected_to new_session_path
  end

  test "GET /admin/events/pending redirects non-admin user" do
    sign_in_as(@regular)
    get admin_pending_events_path
    assert_redirected_to root_path
  end

  test "GET /admin/events/pending returns 200 for admin" do
    sign_in_as(@admin)
    get admin_pending_events_path
    assert_response :success
  end

  # POST /admin/events/:id/approve

  test "POST /admin/events/:id/approve approves event for admin" do
    sign_in_as(@admin)
    assert_not @unapproved_event.approved?

    post admin_approve_event_path(@unapproved_event)
    assert_redirected_to admin_pending_events_path

    @unapproved_event.reload
    assert @unapproved_event.approved?
  end

  test "POST /admin/events/:id/approve redirects non-admin" do
    sign_in_as(@regular)
    post admin_approve_event_path(@unapproved_event)
    assert_redirected_to root_path

    @unapproved_event.reload
    assert_not @unapproved_event.approved?
  end

  # DELETE /admin/events/:id/reject

  test "DELETE /admin/events/:id/reject destroys event for admin" do
    sign_in_as(@admin)
    assert_difference "Event.count", -1 do
      delete admin_reject_event_path(@unapproved_event)
    end
    assert_redirected_to admin_pending_events_path
  end

  test "DELETE /admin/events/:id/reject redirects non-admin" do
    sign_in_as(@regular)
    assert_no_difference "Event.count" do
      delete admin_reject_event_path(@unapproved_event)
    end
    assert_redirected_to root_path
  end
end
