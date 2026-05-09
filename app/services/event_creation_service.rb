class EventCreationService
  Result = Struct.new(:events, :errors, :display_event, keyword_init: true) do
    def success?
      errors.empty?
    end

    def single?
      events.length == 1
    end
  end

  # @param user [User] the user creating the events
  # @param event_params [ActionController::Parameters] shared event attributes
  # @param dates [Array<ActionController::Parameters>] date attribute hashes
  # @return [Result] result object with success/failure, events, and errors
  def self.call(user:, event_params:, dates:)
    new(user: user, event_params: event_params, dates: dates).call
  end

  def initialize(user:, event_params:, dates:)
    @user = user
    @event_params = event_params
    @dates = dates
  end

  # @return [Result]
  def call
    return empty_dates_result if @dates.empty?

    events = build_events
    return validation_failure_result(events) unless events.all?(&:valid?)

    if save_in_transaction(events)
      Result.new(events: events, errors: [])
    else
      transaction_failure_result(events)
    end
  end

  private

  # @return [Result] result when no dates are provided
  def empty_dates_result
    display_event = build_display_event
    Result.new(
      events: [],
      errors: ['At least one date is required'],
      display_event: display_event
    )
  end

  # @return [Array<Event>] built (unsaved) events for each date
  def build_events
    @dates.map do |date_attrs|
      @user.events.build(@event_params.merge(date_attrs))
    end
  end

  # @return [Event] a display event with locations for re-rendering the form
  def build_display_event
    event = @user.events.build(@event_params)
    event.event_locations.build if event.event_locations.empty?
    event
  end

  # @param events [Array<Event>] events that failed validation
  # @return [Result] result with formatted validation errors
  def validation_failure_result(events)
    display_event = build_display_event
    errors = collect_validation_errors(events)
    errors.each { |msg| display_event.errors.add(:base, msg) }

    Result.new(
      events: events,
      errors: errors,
      display_event: display_event
    )
  end

  # @param events [Array<Event>] events where at least one failed to save
  # @return [Result] result with formatted save errors
  def transaction_failure_result(events)
    display_event = build_display_event
    failing = events.select { |e| e.errors.any? }

    errors = if failing.any?
      collect_validation_errors(events, source: failing)
    else
      ['Failed to save events. Please try again.']
    end

    errors.each { |msg| display_event.errors.add(:base, msg) }

    Result.new(
      events: events,
      errors: errors,
      display_event: display_event
    )
  end

  # @param events [Array<Event>] all events (for indexing)
  # @param source [Array<Event>] events with errors (defaults to all)
  # @return [Array<String>] formatted error messages
  def collect_validation_errors(events, source: nil)
    source ||= events
    single = events.length == 1

    source.flat_map do |ev|
      index = events.index(ev)
      ev.errors.full_messages.map do |msg|
        single ? msg : "Date #{index + 1}: #{msg}"
      end
    end
  end

  # @param events [Array<Event>] validated events to save
  # @return [Boolean] true if all events saved successfully
  def save_in_transaction(events)
    success = false
    ActiveRecord::Base.transaction do
      success = events.all?(&:save)
      raise ActiveRecord::Rollback unless success
    end
    success
  end
end
