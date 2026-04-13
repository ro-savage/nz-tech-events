require "test_helper"

class CleanupExpiredSessionsJobTest < ActiveJob::TestCase
  setup do
    @user = users(:regular)
  end

  test "deletes sessions older than 30 days" do
    old_session = @user.sessions.create!(
      user_agent: "old-browser",
      ip_address: "1.2.3.4"
    )
    old_session.update_column(:updated_at, 31.days.ago)

    assert_difference "Session.count", -1 do
      CleanupExpiredSessionsJob.perform_now
    end

    assert_nil Session.find_by(id: old_session.id)
  end

  test "keeps sessions newer than 30 days" do
    recent_session = @user.sessions.create!(
      user_agent: "new-browser",
      ip_address: "1.2.3.4"
    )
    recent_session.update_column(:updated_at, 29.days.ago)

    assert_no_difference "Session.count" do
      CleanupExpiredSessionsJob.perform_now
    end

    assert Session.find_by(id: recent_session.id).present?
  end

  test "handles zero expired sessions gracefully" do
    Session.delete_all

    assert_nothing_raised do
      CleanupExpiredSessionsJob.perform_now
    end
  end

  test "deletes multiple expired sessions in one run" do
    3.times do |i|
      s = @user.sessions.create!(
        user_agent: "expired-#{i}",
        ip_address: "1.2.3.#{i}"
      )
      s.update_column(:updated_at, 45.days.ago)
    end

    assert_difference "Session.count", -3 do
      CleanupExpiredSessionsJob.perform_now
    end
  end

  test "keeps sessions updated within the last 30 days" do
    recent_session = @user.sessions.create!(
      user_agent: "recent",
      ip_address: "1.2.3.4"
    )
    recent_session.update_column(:updated_at, 25.days.ago)

    initial_count = Session.count

    CleanupExpiredSessionsJob.perform_now

    assert_equal initial_count, Session.count
    assert Session.find_by(id: recent_session.id).present?
  end
end
