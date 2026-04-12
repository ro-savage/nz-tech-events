class Api::V1::EventsController < Api::V1::BaseController
  rate_limit to: 120, within: 1.minute,
             by: -> { rate_limit_key },
             only: %i[index show mine],
             name: "api-reads"

  rate_limit to: 30, within: 1.minute,
             by: -> { rate_limit_key },
             only: %i[create update destroy],
             name: "api-writes"

  before_action :require_api_token, only: %i[mine create update destroy]
  before_action :set_event, only: %i[show]
  before_action :set_own_event, only: %i[update destroy]

  # GET /api/v1/events
  def index
    events = Event.approved.includes(:event_locations, :rich_text_description)

    events = if params[:scope] == "past"
      events.past
    else
      events.upcoming
    end

    events = events.by_region(params[:region]) if params[:region].present?
    events = events.by_city(params[:city]) if params[:city].present?
    events = events.by_event_type(params[:event_type]) if params[:event_type].present?

    result = paginate(events)
    render json: {
      events: result[:records].map { |e| serialize_event(e) },
      meta: result[:meta]
    }
  end

  # GET /api/v1/events/:id
  def show
    render json: serialize_event(@event)
  end

  # GET /api/v1/events/mine
  def mine
    events = current_user.events.includes(:event_locations, :rich_text_description).order(start_date: :desc)
    result = paginate(events)
    render json: {
      events: result[:records].map { |e| serialize_event(e) },
      meta: result[:meta]
    }
  end

  # POST /api/v1/events
  def create
    @event = current_user.events.build(api_event_params)
    build_locations

    markdown_valid = process_markdown

    if markdown_valid && @event.save
      render json: serialize_event(@event.reload), status: :created
    else
      @event.valid?
      @event.errors.add(:description_markdown, @markdown_error) unless markdown_valid
      render_validation_errors(@event)
    end
  end

  # PATCH /api/v1/events/:id
  def update
    @event.assign_attributes(api_event_params)
    build_locations if params.dig(:event, :locations).present?

    if params.dig(:event, :description_markdown).present?
      unless process_markdown
        render_validation_errors(@event)
        return
      end
    end

    if @event.save
      render json: serialize_event(@event.reload)
    else
      render_validation_errors(@event)
    end
  end

  # DELETE /api/v1/events/:id
  def destroy
    @event.destroy
    render json: { message: "Event deleted successfully" }
  end

  private

  def set_event
    @event = Event.approved.includes(:event_locations, :rich_text_description).find(params[:id])
  end

  def set_own_event
    @event = current_user.events.includes(:event_locations, :rich_text_description).find(params[:id])
  end

  def api_event_params
    params.require(:event).permit(
      :title, :short_summary, :start_date, :end_date,
      :start_time, :end_time, :cost, :event_type,
      :registration_url, :address, :source, :source_url
    )
  end

  def process_markdown
    markdown_input = params.dig(:event, :description_markdown)
    result = MarkdownConverter.call(markdown_input)

    if result.valid?
      @event.description = result.html
      @event.description_markdown = result.sanitized_markdown
      true
    else
      @markdown_error = result.error
      @event.errors.add(:description_markdown, @markdown_error)
      false
    end
  end

  def build_locations
    locations_data = params.dig(:event, :locations)
    return unless locations_data.is_a?(Array)

    # Mark existing locations for destruction
    @event.event_locations.each { |loc| loc.mark_for_destruction }

    # Build new locations from the submitted array
    locations_data.each_with_index do |loc, index|
      @event.event_locations.build(
        region: loc[:region],
        city: loc[:city],
        position: index
      )
    end
  end
end
