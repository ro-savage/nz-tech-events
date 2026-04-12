class Api::V1::SpecController < Api::V1::BaseController
  def show
    render json: {
      api: {
        name: "NZ Tech Events API",
        version: "v1",
        base_url: "#{request.base_url}/api/v1"
      },
      authentication: {
        type: "bearer",
        header: "Authorization: Bearer <token>",
        description: "Approved organisers and admins can generate tokens from the web UI at /api_tokens"
      },
      endpoints: [
        {
          method: "GET",
          path: "/api/v1/events",
          auth_required: false,
          description: "List approved events (upcoming by default)",
          parameters: [
            { name: "scope", type: "string", required: false, description: "upcoming (default) or past" },
            { name: "region", type: "string", required: false, description: "Filter by region key" },
            { name: "city", type: "string", required: false, description: "Filter by city (requires region)" },
            { name: "event_type", type: "string", required: false, description: "Filter by event type" },
            { name: "page", type: "integer", required: false, description: "Page number (default: 1)" },
            { name: "per_page", type: "integer", required: false, description: "Items per page (default: 25, max: 100)" }
          ]
        },
        {
          method: "GET",
          path: "/api/v1/events/:id",
          auth_required: false,
          description: "Show a single approved event"
        },
        {
          method: "GET",
          path: "/api/v1/events/mine",
          auth_required: true,
          description: "List token holder's own events (including unapproved)"
        },
        {
          method: "POST",
          path: "/api/v1/events",
          auth_required: true,
          description: "Create a new event",
          required_fields: %w[title description_markdown start_date event_type locations],
          optional_fields: %w[short_summary end_date start_time end_time cost registration_url address source source_url]
        },
        {
          method: "PATCH",
          path: "/api/v1/events/:id",
          auth_required: true,
          description: "Update an event you own (partial updates supported)"
        },
        {
          method: "DELETE",
          path: "/api/v1/events/:id",
          auth_required: true,
          description: "Delete an event you own"
        }
      ],
      enums: {
        event_types: Event.event_types.keys,
        regions: EventLocation.regions.keys
      },
      rate_limits: {
        reads: { limit: 120, window: "1 minute", endpoints: %w[index show mine] },
        writes: { limit: 30, window: "1 minute", endpoints: %w[create update destroy] }
      },
      error_format: {
        single_error: { error: "string", status: "integer" },
        validation_errors: { errors: { field: [ "array of messages" ] }, status: 422 }
      }
    }
  end
end
