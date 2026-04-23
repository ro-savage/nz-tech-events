require 'test_helper'

class SocialMetaTagsTest < ActionDispatch::IntegrationTest
  test 'event show page og:title is the event title, not the site default' do
    event = events(:approved_upcoming)
    get event_path(event)
    assert_response :success
    assert_match(
      /<meta property="og:title" content="#{Regexp.escape(ERB::Util.html_escape(event.title))}">/,
      response.body
    )
  end

  test 'event show page og:description is the event summary, not the site default' do
    event = events(:approved_upcoming)
    get event_path(event)
    assert_response :success
    assert_match(
      /<meta property="og:description" content="#{Regexp.escape(ERB::Util.html_escape(event.display_summary(limit: 200)))}">/,
      response.body
    )
  end

  test 'event show page emits exactly one og:title, og:description, og:type' do
    event = events(:approved_upcoming)
    get event_path(event)
    assert_response :success
    assert_equal 1, response.body.scan(/<meta property="og:title"/).size
    assert_equal 1, response.body.scan(/<meta property="og:description"/).size
    assert_equal 1, response.body.scan(/<meta property="og:type"/).size
  end

  test 'event show page includes twitter:card summary' do
    event = events(:approved_upcoming)
    get event_path(event)
    assert_response :success
    assert_match(/<meta name="twitter:card" content="summary">/, response.body)
  end

  test 'event show page includes og:url with absolute event URL' do
    event = events(:approved_upcoming)
    get event_path(event)
    assert_response :success
    assert_match(
      /<meta property="og:url" content="#{Regexp.escape(event_url(event))}">/,
      response.body
    )
  end

  test 'homepage does not render an event-specific og:title' do
    event = events(:approved_upcoming)
    get root_path
    assert_response :success
    assert_no_match(
      /<meta property="og:title" content="#{Regexp.escape(event.title)}">/,
      response.body
    )
    assert_equal 1, response.body.scan(/<meta property="og:title"/).size
  end
end
