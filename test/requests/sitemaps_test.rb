require "test_helper"

class SitemapsRequestTest < ActionDispatch::IntegrationTest
  test "GET /sitemap.xml returns 200 with XML content type" do
    get sitemap_path

    assert_response :success
    assert_match "application/xml", response.content_type
  end

  test "sitemap contains root URL" do
    get sitemap_path

    assert_includes response.body, root_url
  end

  test "sitemap contains about URL" do
    get sitemap_path

    assert_includes response.body, about_url
  end

  test "sitemap contains past events URL" do
    get sitemap_path

    assert_includes response.body, past_events_url
  end

  test "sitemap contains approved event URLs" do
    approved_event = events(:approved_upcoming)

    get sitemap_path

    assert_includes response.body, event_url(approved_event)
  end

  test "sitemap does NOT contain unapproved event URLs" do
    unapproved_event = events(:unapproved_upcoming)

    get sitemap_path

    assert_not_includes response.body, event_url(unapproved_event)
  end

  test "sitemap contains lastmod timestamps" do
    get sitemap_path

    assert_includes response.body, "<lastmod>"
  end

  test "sitemap has valid XML structure" do
    get sitemap_path

    assert_includes response.body, '<?xml version="1.0" encoding="UTF-8"?>'
    assert_includes response.body, 'xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"'
  end
end
