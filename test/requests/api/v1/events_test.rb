require "test_helper"

class Api::V1::EventsControllerTest < ActionDispatch::IntegrationTest
  # --- Helper ---

  def api_headers(token = nil)
    headers = { "Accept" => "application/json" }
    headers["Authorization"] = "Bearer #{token}" if token
    headers
  end

  def organiser_token
    "techevents_testtoken1234567890abcdef"
  end

  def admin_token_value
    "techevents_admintokenabcdef1234567890"
  end

  # ============================================================
  # GET /api/v1/events (Index)
  # ============================================================

  test "index returns approved upcoming events" do
    get api_v1_events_path, headers: api_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("events")
    assert json.key?("meta")

    titles = json["events"].map { |e| e["title"] }
    assert_includes titles, events(:approved_upcoming).title
    assert_not_includes titles, events(:unapproved_upcoming).title
    assert_not_includes titles, events(:past_event).title
  end

  test "index returns past events when scope=past" do
    get api_v1_events_path, params: { scope: "past" }, headers: api_headers
    assert_response :success

    json = JSON.parse(response.body)
    titles = json["events"].map { |e| e["title"] }
    assert_includes titles, events(:past_event).title
    assert_not_includes titles, events(:approved_upcoming).title
  end

  test "index includes pagination meta" do
    get api_v1_events_path, headers: api_headers
    json = JSON.parse(response.body)

    meta = json["meta"]
    assert meta["current_page"].is_a?(Integer)
    assert meta["total_pages"].is_a?(Integer)
    assert meta["total_count"].is_a?(Integer)
    assert meta["per_page"].is_a?(Integer)
  end

  test "index respects per_page parameter" do
    get api_v1_events_path, params: { per_page: 2 }, headers: api_headers
    json = JSON.parse(response.body)
    assert json["events"].length <= 2
    assert_equal 2, json["meta"]["per_page"]
  end

  test "index caps per_page at 100" do
    get api_v1_events_path, params: { per_page: 999 }, headers: api_headers
    json = JSON.parse(response.body)
    assert_equal 100, json["meta"]["per_page"]
  end

  test "index filters by region" do
    get api_v1_events_path, params: { region: "wellington" }, headers: api_headers
    assert_response :success

    json = JSON.parse(response.body)
    titles = json["events"].map { |e| e["title"] }
    assert_includes titles, events(:approved_upcoming).title
  end

  test "index filters by event_type" do
    get api_v1_events_path, params: { event_type: "networking" }, headers: api_headers
    assert_response :success

    json = JSON.parse(response.body)
    titles = json["events"].map { |e| e["title"] }
    assert_includes titles, events(:free_event).title
  end

  test "index returns JSON content type" do
    get api_v1_events_path, headers: api_headers
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  # ============================================================
  # GET /api/v1/events/:id (Show)
  # ============================================================

  test "show returns approved event" do
    event = events(:approved_upcoming)
    get api_v1_event_path(event), headers: api_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal event.title, json["title"]
    assert_equal event.event_type, json["event_type"]
    assert_equal event.start_date.iso8601, json["start_date"]
    assert json["locations"].is_a?(Array)
    assert json["approved"]
  end

  test "show returns 404 for unapproved event" do
    event = events(:unapproved_upcoming)
    get api_v1_event_path(event), headers: api_headers
    assert_response :not_found

    json = JSON.parse(response.body)
    assert_equal "Not found", json["error"]
  end

  test "show returns 404 for nonexistent event" do
    get api_v1_event_path(id: 999999), headers: api_headers
    assert_response :not_found
  end

  test "show does not include source or source_url" do
    event = events(:approved_upcoming)
    get api_v1_event_path(event), headers: api_headers
    json = JSON.parse(response.body)
    assert_not json.key?("source")
    assert_not json.key?("source_url")
    assert_not json.key?("user_id")
  end

  test "show includes event locations" do
    event = events(:approved_upcoming)
    get api_v1_event_path(event), headers: api_headers
    json = JSON.parse(response.body)

    assert json["locations"].length >= 1
    location = json["locations"].first
    assert location.key?("region")
    assert location.key?("city")
  end

  # ============================================================
  # /api/latest/ alias
  # ============================================================

  test "latest alias works for index" do
    get "/api/latest/events", headers: api_headers
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("events")
  end

  test "latest alias works for show" do
    event = events(:approved_upcoming)
    get "/api/latest/events/#{event.id}", headers: api_headers
    assert_response :success
  end

  # ============================================================
  # GET /api/v1/events/mine (Authenticated)
  # ============================================================

  test "mine requires authentication" do
    get mine_api_v1_events_path, headers: api_headers
    assert_response :unauthorized
  end

  test "mine returns token holder's events including unapproved" do
    get mine_api_v1_events_path, headers: api_headers(organiser_token)
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("events")
    titles = json["events"].map { |e| e["title"] }
    assert_includes titles, events(:organiser_event).title
  end

  test "mine does not return other users' events" do
    get mine_api_v1_events_path, headers: api_headers(organiser_token)
    json = JSON.parse(response.body)
    titles = json["events"].map { |e| e["title"] }
    assert_not_includes titles, events(:approved_upcoming).title
  end

  # ============================================================
  # POST /api/v1/events (Create)
  # ============================================================

  test "create requires authentication" do
    post api_v1_events_path,
      params: { event: { title: "Test" } },
      headers: api_headers,
      as: :json
    assert_response :unauthorized
  end

  test "create with valid params returns 201" do
    assert_difference("Event.count", 1) do
      post api_v1_events_path,
        params: {
          event: {
            title: "New API Event",
            description_markdown: "A **great** event",
            start_date: 30.days.from_now.to_date.iso8601,
            event_type: "meetup",
            locations: [ { region: "auckland", city: "Auckland CBD" } ]
          }
        },
        headers: api_headers(organiser_token),
        as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New API Event", json["title"]
    assert_equal "meetup", json["event_type"]
    assert json["approved"]  # organiser's events auto-approve
    assert_equal "A **great** event", json["description_markdown"]
    assert json["description"].present?  # plain text version
    assert_equal 1, json["locations"].length
  end

  test "create with missing required fields returns 422" do
    post api_v1_events_path,
      params: { event: { title: "" } },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].key?("title")
  end

  test "create with blank description_markdown returns 422" do
    post api_v1_events_path,
      params: {
        event: {
          title: "Missing Description",
          description_markdown: "",
          start_date: 30.days.from_now.to_date.iso8601,
          event_type: "meetup",
          locations: [ { region: "auckland" } ]
        }
      },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].key?("description_markdown")
  end

  test "create with invalid token returns 401" do
    post api_v1_events_path,
      params: { event: { title: "Test" } },
      headers: api_headers("techevents_invalidtoken"),
      as: :json
    assert_response :unauthorized
  end

  test "create with invalid event_type returns 422" do
    post api_v1_events_path,
      params: {
        event: {
          title: "Bad Type",
          description_markdown: "Test",
          start_date: 30.days.from_now.to_date.iso8601,
          event_type: "bogus_type",
          locations: [ { region: "auckland" } ]
        }
      },
      headers: api_headers(organiser_token),
      as: :json
    assert_response :unprocessable_entity
  end

  test "create with invalid region returns 422" do
    post api_v1_events_path,
      params: {
        event: {
          title: "Bad Region",
          description_markdown: "Test",
          start_date: 30.days.from_now.to_date.iso8601,
          event_type: "meetup",
          locations: [ { region: "narnia" } ]
        }
      },
      headers: api_headers(organiser_token),
      as: :json
    assert_response :unprocessable_entity
  end

  test "create strips HTML from stored description_markdown" do
    post api_v1_events_path,
      params: {
        event: {
          title: "XSS Test",
          description_markdown: "Hello <script>alert('xss')</script> world",
          start_date: 30.days.from_now.to_date.iso8601,
          event_type: "meetup",
          locations: [ { region: "auckland" } ]
        }
      },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_not_includes json["description_markdown"], "<script>"
    assert_includes json["description_markdown"], "Hello"
    assert_includes json["description_markdown"], "world"
  end

  test "create with all optional fields" do
    post api_v1_events_path,
      params: {
        event: {
          title: "Full Event",
          description_markdown: "Description here",
          short_summary: "Brief summary",
          start_date: 30.days.from_now.to_date.iso8601,
          end_date: 31.days.from_now.to_date.iso8601,
          start_time: "09:00",
          end_time: "17:00",
          cost: "$50",
          event_type: "conference",
          registration_url: "https://example.com/register",
          address: "123 Queen St",
          locations: [
            { region: "auckland", city: "Auckland CBD" },
            { region: "online" }
          ]
        }
      },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 2, json["locations"].length
    assert_equal "123 Queen St", json["address"]
    assert_equal "$50", json["cost"]
  end

  test "create saves source and source_url" do
    post api_v1_events_path,
      params: {
        event: {
          title: "Sourced Event",
          description_markdown: "From external source",
          start_date: 30.days.from_now.to_date.iso8601,
          event_type: "meetup",
          source: "Events in Aotearoa",
          source_url: "https://example.com/events",
          locations: [ { region: "auckland" } ]
        }
      },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :created
    event = Event.find(JSON.parse(response.body)["id"])
    assert_equal "Events in Aotearoa", event.source
    assert_equal "https://example.com/events", event.source_url
  end

  test "update saves source and source_url" do
    event = events(:organiser_event)
    patch api_v1_event_path(event),
      params: {
        event: {
          source: "Updated Source",
          source_url: "https://example.com/updated"
        }
      },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :success
    event.reload
    assert_equal "Updated Source", event.source
    assert_equal "https://example.com/updated", event.source_url
  end

  test "create does not set legacy region/city on event" do
    post api_v1_events_path,
      params: {
        event: {
          title: "No Legacy",
          description_markdown: "Test",
          start_date: 30.days.from_now.to_date.iso8601,
          event_type: "meetup",
          locations: [ { region: "wellington", city: "Wellington CBD" } ]
        }
      },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :created
    event = Event.find(JSON.parse(response.body)["id"])
    assert_nil event.read_attribute(:region)
  end

  # ============================================================
  # PATCH /api/v1/events/:id (Update)
  # ============================================================

  test "update requires authentication" do
    event = events(:organiser_event)
    patch api_v1_event_path(event),
      params: { event: { title: "Updated" } },
      headers: api_headers,
      as: :json
    assert_response :unauthorized
  end

  test "update own event succeeds" do
    event = events(:organiser_event)
    patch api_v1_event_path(event),
      params: { event: { title: "Updated Title" } },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Title", json["title"]
    assert_equal "Updated Title", event.reload.title
  end

  test "update other user's event returns 404" do
    event = events(:approved_upcoming)  # owned by regular user
    patch api_v1_event_path(event),
      params: { event: { title: "Hijacked" } },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :not_found
  end

  test "update can change description via markdown" do
    event = events(:organiser_event)
    patch api_v1_event_path(event),
      params: { event: { description_markdown: "New **description**" } },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "New **description**", json["description_markdown"]
  end

  test "update can replace locations" do
    event = events(:organiser_event)
    patch api_v1_event_path(event),
      params: {
        event: {
          locations: [
            { region: "wellington", city: "Wellington CBD" },
            { region: "canterbury", city: "Christchurch" }
          ]
        }
      },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json["locations"].length
    regions = json["locations"].map { |l| l["region"] }
    assert_includes regions, "wellington"
    assert_includes regions, "canterbury"
  end

  test "update with invalid data returns 422" do
    event = events(:organiser_event)
    patch api_v1_event_path(event),
      params: { event: { title: "" } },
      headers: api_headers(organiser_token),
      as: :json

    assert_response :unprocessable_entity
  end

  # ============================================================
  # DELETE /api/v1/events/:id (Destroy)
  # ============================================================

  test "destroy requires authentication" do
    event = events(:organiser_event)
    delete api_v1_event_path(event), headers: api_headers
    assert_response :unauthorized
  end

  test "destroy own event succeeds" do
    event = events(:organiser_event)
    assert_difference("Event.count", -1) do
      delete api_v1_event_path(event), headers: api_headers(organiser_token)
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Event deleted successfully", json["message"]
  end

  test "destroy other user's event returns 404" do
    event = events(:approved_upcoming)  # owned by regular user
    delete api_v1_event_path(event), headers: api_headers(organiser_token)
    assert_response :not_found
  end

  test "destroy nonexistent event returns 404" do
    delete api_v1_event_path(id: 999999), headers: api_headers(organiser_token)
    assert_response :not_found
  end
end
