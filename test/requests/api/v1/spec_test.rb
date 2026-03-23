require "test_helper"

class Api::V1::SpecControllerTest < ActionDispatch::IntegrationTest
  test "spec returns JSON" do
    get api_v1_spec_path(format: :json)
    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  test "spec contains API info" do
    get api_v1_spec_path(format: :json)
    json = JSON.parse(response.body)

    assert json.key?("api")
    assert_equal "v1", json["api"]["version"]
    assert json.key?("endpoints")
    assert json.key?("enums")
  end

  test "spec lists all endpoints" do
    get api_v1_spec_path(format: :json)
    json = JSON.parse(response.body)

    paths = json["endpoints"].map { |e| e["path"] }
    assert_includes paths, "/api/v1/events"
    assert_includes paths, "/api/v1/events/:id"
    assert_includes paths, "/api/v1/events/mine"
  end

  test "spec includes enum values" do
    get api_v1_spec_path(format: :json)
    json = JSON.parse(response.body)

    assert json["enums"]["event_types"].is_a?(Array)
    assert_includes json["enums"]["event_types"], "meetup"
    assert json["enums"]["regions"].is_a?(Array)
    assert_includes json["enums"]["regions"], "auckland"
    assert_includes json["enums"]["regions"], "apac"
    assert_includes json["enums"]["regions"], "online"
  end

  test "spec includes authentication info" do
    get api_v1_spec_path(format: :json)
    json = JSON.parse(response.body)
    assert json["authentication"].key?("type")
    assert_equal "bearer", json["authentication"]["type"]
  end

  test "latest alias works for spec" do
    get "/api/latest/spec.json"
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("api")
  end
end
