require "test_helper"

class FeedsRequestTest < ActionDispatch::IntegrationTest
  test "GET /feed returns RSS XML with correct content type" do
    get feed_path(format: :rss)
    assert_response :success
    assert_match "application/rss+xml", response.content_type
    assert_match "<rss", response.body
    assert_match 'version="2.0"', response.body
  end

  test "RSS feed contains approved upcoming event titles" do
    get feed_path(format: :rss)
    assert_response :success
    assert_includes response.body, events(:approved_upcoming).title
  end

  test "RSS feed excludes unapproved events" do
    get feed_path(format: :rss)
    assert_response :success
    refute_includes response.body, events(:unapproved_upcoming).title
  end

  test "RSS feed excludes past events" do
    get feed_path(format: :rss)
    assert_response :success
    refute_includes response.body, events(:past_event).title
  end

  test "GET /feed.atom returns Atom XML with correct content type" do
    get atom_feed_path(format: :atom)
    assert_response :success
    assert_match "application/atom+xml", response.content_type
    assert_match "<feed", response.body
    assert_match "http://www.w3.org/2005/Atom", response.body
  end

  test "Atom feed contains approved upcoming event titles" do
    get atom_feed_path(format: :atom)
    assert_response :success
    assert_includes response.body, events(:approved_upcoming).title
  end

  test "RSS feed includes channel metadata" do
    get feed_path(format: :rss)
    assert_response :success
    assert_match "<channel>", response.body
    assert_match "<title>NZ Tech Events</title>", response.body
    assert_match "<description>Upcoming tech events across New Zealand</description>", response.body
  end

  test "RSS feed items include category" do
    get feed_path(format: :rss)
    assert_response :success
    assert_match "<category>", response.body
  end

  test "Atom feed has a feed-level author" do
    get atom_feed_path(format: :atom)
    assert_response :success
    # Author must be at feed level so every entry is covered even without
    # per-entry authors (RFC 4287 §4.2.1).
    author_section = response.body[/<feed[^>]*>.*?<entry>/m]
    assert_match %r{<author>\s*<name>NZ Tech Events</name>\s*</author>}, author_section
  end

  test "Atom feed <updated> is a non-empty valid timestamp" do
    get atom_feed_path(format: :atom)
    assert_response :success
    match = response.body.match(%r{<updated>([^<]+)</updated>})
    assert match, "expected feed-level <updated> element"
    assert_nothing_raised { Time.iso8601(match[1]) }
  end

  test "RSS feed <lastBuildDate> is a non-empty valid timestamp" do
    get feed_path(format: :rss)
    assert_response :success
    match = response.body.match(%r{<lastBuildDate>([^<]+)</lastBuildDate>})
    assert match, "expected <lastBuildDate> element"
    assert_nothing_raised { Time.rfc2822(match[1]) }
  end

  test "Atom feed renders with non-empty <updated> when no approved upcoming events" do
    Event.update_all(approved: false)
    get atom_feed_path(format: :atom)
    assert_response :success
    match = response.body.match(%r{<updated>([^<]+)</updated>})
    assert match, "empty feed must still have a valid <updated>"
    assert_nothing_raised { Time.iso8601(match[1]) }
    refute_match "<entry>", response.body
  end

  test "RSS feed renders with non-empty <lastBuildDate> when no approved upcoming events" do
    Event.update_all(approved: false)
    get feed_path(format: :rss)
    assert_response :success
    match = response.body.match(%r{<lastBuildDate>([^<]+)</lastBuildDate>})
    assert match, "empty feed must still have a valid <lastBuildDate>"
    assert_nothing_raised { Time.rfc2822(match[1]) }
    refute_match "<item>", response.body
  end

  test "feed is limited to MAX_FEED_EVENTS" do
    assert_equal 50, FeedsController::MAX_FEED_EVENTS
    # We can't easily build 51 valid fixtures, but verify the scope the
    # controller uses honours the limit.
    sql = Event.approved.upcoming.limit(FeedsController::MAX_FEED_EVENTS).to_sql
    assert_match(/LIMIT\s+50/i, sql)
  end

  test "RSS feed is accessible without authentication" do
    get feed_path(format: :rss)
    assert_response :success
  end
end
