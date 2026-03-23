class Api::V1::BaseController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from ArgumentError, with: :invalid_parameter

  private

  # --- Authentication ---

  def current_api_token
    @current_api_token ||= authenticate_bearer_token
  end

  def current_user
    @current_user ||= current_api_token&.user
  end

  def require_api_token
    unless current_user
      render json: { error: "Unauthorized", status: 401 }, status: :unauthorized
    end
  end

  def extract_bearer_token
    header = request.headers["Authorization"]
    return nil unless header&.start_with?("Bearer ")
    header.remove("Bearer ").strip
  end

  def authenticate_bearer_token
    raw_token = extract_bearer_token
    return nil unless raw_token

    token = ApiToken.authenticate(raw_token)

    if token
      Current.user = token.user
      token.touch_last_used!
    end

    token
  end

  # --- Error Handling ---

  def not_found
    render json: { error: "Not found", status: 404 }, status: :not_found
  end

  def bad_request(exception)
    render json: { error: exception.message, status: 400 }, status: :bad_request
  end

  def invalid_parameter(exception)
    render json: { error: exception.message, status: 422 }, status: :unprocessable_entity
  end

  def render_validation_errors(record)
    render json: { errors: record.errors.messages, status: 422 }, status: :unprocessable_entity
  end

  def render_forbidden
    render json: { error: "Forbidden", status: 403 }, status: :forbidden
  end

  # --- Pagination ---

  def page_number
    [params.fetch(:page, 1).to_i, 1].max
  end

  def per_page
    params.fetch(:per_page, 25).to_i.clamp(1, 100)
  end

  def paginate(scope)
    total = scope.count
    records = scope.offset((page_number - 1) * per_page).limit(per_page)

    {
      records: records,
      meta: {
        current_page: page_number,
        total_pages: (total.to_f / per_page).ceil,
        total_count: total,
        per_page: per_page
      }
    }
  end

  # --- Rate Limiting Key ---

  def rate_limit_key
    @rate_limit_key ||= begin
      token = extract_bearer_token
      token.present? ? Digest::SHA256.hexdigest(token).first(16) : request.remote_ip
    end
  end

  # --- Event Serialization ---

  def serialize_event(event)
    {
      id: event.id,
      title: event.title,
      description: event.description&.to_plain_text,
      description_markdown: event.description_markdown,
      short_summary: event.short_summary,
      start_date: event.start_date&.iso8601,
      end_date: event.end_date&.iso8601,
      start_time: event.start_time&.strftime("%H:%M"),
      end_time: event.end_time&.strftime("%H:%M"),
      cost: event.cost,
      event_type: event.event_type,
      registration_url: event.registration_url,
      address: event.address,
      locations: event.event_locations.map { |loc|
        { region: loc.region, city: loc.city }
      },
      approved: event.approved,
      created_at: event.created_at&.iso8601,
      updated_at: event.updated_at&.iso8601
    }
  end
end
