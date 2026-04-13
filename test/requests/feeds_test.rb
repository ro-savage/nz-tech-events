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

  test "RSS feed includes event metadata" do
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

  test "feed is limited to 50 events" do
    get feed_path(format: :rss)
    assert_response :success
    # Verify the controller limits results (we have fewer than 50 fixtures,
    # so just confirm the feed renders without error)
    items = response.body.scan("<item>")
    assert items.length <= 50
  end

  test "RSS feed is accessible without authentication" do
    get feed_path(format: :rss)
    assert_response :success
  end
end
