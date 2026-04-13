require "application_system_test_case"

class AdminFlowsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
  end

  test "admin sees pending events page" do
    sign_in_as(@admin)

    find(".hamburger").click
    click_on "Pending Events"

    assert_text "Pending Event Approvals"
    assert_text "Startup Hackathon"
  end

  test "admin approves a pending event" do
    sign_in_as(@admin)

    visit admin_pending_events_path

    assert_text "Startup Hackathon"

    accept_confirm "Approve this event?" do
      click_button "Approve", match: :first
    end

    assert_text "Event approved successfully"
  end

  test "admin sees users page" do
    sign_in_as(@admin)

    find(".hamburger").click
    click_on "Users"

    assert_text "User Management"
    assert_text users(:regular).email_address
    assert_text users(:organiser).email_address
  end

  test "admin toggles approved organiser status" do
    sign_in_as(@admin)

    visit users_path

    assert_text "Regular User"

    click_button "Make Approved Organiser", match: :first

    assert_text "approved organiser"
  end
end
