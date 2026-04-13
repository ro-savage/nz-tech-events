require 'test_helper'

class EventCreationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular)
    @organiser = users(:organiser)
    @valid_params = ActionController::Parameters.new(
      title: 'Test Event',
      event_type: 'meetup',
      description: 'A test event description',
      event_locations_attributes: {
        '0' => { region: 'wellington', city: 'Wellington CBD' }
      }
    ).permit!
  end

  # -- Empty dates --

  test 'returns failure when no dates provided' do
    result = EventCreationService.call(
      user: @user,
      event_params: @valid_params,
      dates: []
    )

    assert_not result.success?
    assert_includes result.errors, 'At least one date is required'
    assert_empty result.events
    assert_not_nil result.display_event
    assert result.display_event.event_locations.any?
  end

  # -- Single date success --

  test 'creates one event with a single valid date' do
    dates = [ActionController::Parameters.new(
      start_date: 2.weeks.from_now.to_date.to_s
    ).permit!]

    assert_difference 'Event.count', 1 do
      result = EventCreationService.call(
        user: @user,
        event_params: @valid_params,
        dates: dates
      )

      assert result.success?
      assert result.single?
      assert_equal 1, result.events.length
      assert_equal 'Test Event', result.events.first.title
    end
  end

  # -- Multiple dates success --

  test 'creates multiple events with multiple valid dates' do
    dates = [
      ActionController::Parameters.new(
        start_date: 2.weeks.from_now.to_date.to_s
      ).permit!,
      ActionController::Parameters.new(
        start_date: 4.weeks.from_now.to_date.to_s
      ).permit!,
      ActionController::Parameters.new(
        start_date: 6.weeks.from_now.to_date.to_s
      ).permit!
    ]

    assert_difference 'Event.count', 3 do
      result = EventCreationService.call(
        user: @organiser,
        event_params: @valid_params,
        dates: dates
      )

      assert result.success?
      assert_not result.single?
      assert_equal 3, result.events.length
    end
  end

  # -- Validation failure (single date) --

  test 'returns failure with errors for invalid single event' do
    invalid_params = ActionController::Parameters.new(
      title: '',
      event_type: 'meetup',
      description: 'A description',
      event_locations_attributes: {
        '0' => { region: 'wellington', city: 'Wellington CBD' }
      }
    ).permit!

    dates = [ActionController::Parameters.new(
      start_date: 2.weeks.from_now.to_date.to_s
    ).permit!]

    assert_no_difference 'Event.count' do
      result = EventCreationService.call(
        user: @user,
        event_params: invalid_params,
        dates: dates
      )

      assert_not result.success?
      assert result.errors.any? { |e| e.include?("Title") || e.include?("title") }
      assert_not_nil result.display_event
    end
  end

  # -- Validation failure (multiple dates, one invalid) --

  test 'returns failure when one of multiple dates is invalid' do
    dates = [
      ActionController::Parameters.new(
        start_date: 4.weeks.from_now.to_date.to_s
      ).permit!,
      ActionController::Parameters.new(
        start_date: 2.weeks.from_now.to_date.to_s,
        end_date: 1.week.from_now.to_date.to_s
      ).permit!
    ]

    assert_no_difference 'Event.count' do
      result = EventCreationService.call(
        user: @user,
        event_params: @valid_params,
        dates: dates
      )

      assert_not result.success?
      assert result.errors.any? { |e| e.include?('Date 2:') }
    end
  end

  # -- Multi-date error prefix format --

  test 'prefixes errors with date number for multiple dates' do
    invalid_params = ActionController::Parameters.new(
      title: '',
      event_type: 'meetup',
      description: 'A description',
      event_locations_attributes: {
        '0' => { region: 'wellington', city: 'Wellington CBD' }
      }
    ).permit!

    dates = [
      ActionController::Parameters.new(
        start_date: 2.weeks.from_now.to_date.to_s
      ).permit!,
      ActionController::Parameters.new(
        start_date: 4.weeks.from_now.to_date.to_s
      ).permit!
    ]

    result = EventCreationService.call(
      user: @user,
      event_params: invalid_params,
      dates: dates
    )

    assert_not result.success?
    assert result.errors.all? { |e| e.match?(/\ADate \d+:/) }
  end

  # -- Single date errors have no prefix --

  test 'does not prefix errors for single date' do
    invalid_params = ActionController::Parameters.new(
      title: '',
      event_type: 'meetup',
      description: 'A description',
      event_locations_attributes: {
        '0' => { region: 'wellington', city: 'Wellington CBD' }
      }
    ).permit!

    dates = [ActionController::Parameters.new(
      start_date: 2.weeks.from_now.to_date.to_s
    ).permit!]

    result = EventCreationService.call(
      user: @user,
      event_params: invalid_params,
      dates: dates
    )

    assert_not result.success?
    assert result.errors.none? { |e| e.match?(/\ADate \d+:/) }
  end

  # -- Transaction rollback --

  test 'rolls back all events when transaction fails' do
    dates = [
      ActionController::Parameters.new(
        start_date: 4.weeks.from_now.to_date.to_s
      ).permit!,
      ActionController::Parameters.new(
        start_date: 2.weeks.from_now.to_date.to_s,
        end_date: 1.week.from_now.to_date.to_s
      ).permit!
    ]

    assert_no_difference 'Event.count' do
      EventCreationService.call(
        user: @user,
        event_params: @valid_params,
        dates: dates
      )
    end
  end

  # -- Display event has locations built --

  test 'display event has locations built on failure' do
    result = EventCreationService.call(
      user: @user,
      event_params: ActionController::Parameters.new(
        title: '',
        event_type: 'meetup',
        description: 'Desc'
      ).permit!,
      dates: [ActionController::Parameters.new(
        start_date: 2.weeks.from_now.to_date.to_s
      ).permit!]
    )

    assert_not result.success?
    assert result.display_event.event_locations.any?
  end

  # -- Auto-approval via model callback --

  test 'events created by organiser are auto-approved' do
    dates = [ActionController::Parameters.new(
      start_date: 2.weeks.from_now.to_date.to_s
    ).permit!]

    result = EventCreationService.call(
      user: @organiser,
      event_params: @valid_params,
      dates: dates
    )

    assert result.success?
    assert result.events.first.approved?
  end

  test 'events created by regular user are not auto-approved' do
    dates = [ActionController::Parameters.new(
      start_date: 2.weeks.from_now.to_date.to_s
    ).permit!]

    result = EventCreationService.call(
      user: @user,
      event_params: @valid_params,
      dates: dates
    )

    assert result.success?
    assert_not result.events.first.approved?
  end

  # -- Missing location validation --

  test 'returns failure when no location provided' do
    no_location_params = ActionController::Parameters.new(
      title: 'Test Event',
      event_type: 'meetup',
      description: 'A description'
    ).permit!

    dates = [ActionController::Parameters.new(
      start_date: 2.weeks.from_now.to_date.to_s
    ).permit!]

    result = EventCreationService.call(
      user: @user,
      event_params: no_location_params,
      dates: dates
    )

    assert_not result.success?
    assert result.errors.any? { |e| e.downcase.include?('location') }
  end

  # -- Display event errors are populated --

  test 'display event has errors populated on validation failure' do
    invalid_params = ActionController::Parameters.new(
      title: '',
      event_type: 'meetup',
      description: 'Desc',
      event_locations_attributes: {
        '0' => { region: 'wellington', city: 'Wellington CBD' }
      }
    ).permit!

    dates = [ActionController::Parameters.new(
      start_date: 2.weeks.from_now.to_date.to_s
    ).permit!]

    result = EventCreationService.call(
      user: @user,
      event_params: invalid_params,
      dates: dates
    )

    assert_not result.success?
    assert result.display_event.errors.any?
  end
end
