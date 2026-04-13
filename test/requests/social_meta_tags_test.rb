require 'test_helper'

class SocialMetaTagsTest < ActionDispatch::IntegrationTest
  test 'event show page includes og:title with event title' do
    event = events(:approved_upcoming)
    get event_path(event)
    assert_response :success
    assert_includes response.body, "og:title"
    assert_includes response.body, event.title
  end

  test 'event show page includes og:description' do
    event = events(:approved_upcoming)
    get event_path(event)
    assert_response :success
    assert_includes response.body, "og:description"
    assert_includes response.body, event.display_summary(limit: 200)
  end

  test 'event show page includes twitter:card' do
    event = events(:approved_upcoming)
    get event_path(event)
    assert_response :success
    assert_includes response.body, 'twitter:card'
    assert_includes response.body, 'summary'
  end

  test 'event show page includes og:url with event URL' do
    event = events(:approved_upcoming)
    get event_path(event)
    assert_response :success
    assert_includes response.body, "og:url"
    assert_includes response.body, event_url(event)
  end

  test 'homepage does not include event-specific og:title' do
    event = events(:approved_upcoming)
    get root_path
    assert_response :success
    assert_no_match(
      /<meta property="og:title" content="#{Regexp.escape(event.title)}">/,
      response.body
    )
  end
end
