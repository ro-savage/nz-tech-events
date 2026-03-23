require "test_helper"

class Api::DocsControllerTest < ActionDispatch::IntegrationTest
  test "docs page renders successfully" do
    get api_docs_path
    assert_response :success
  end

  test "docs page contains key sections" do
    get api_docs_path
    assert_select "h1", text: /API/
    assert_select "code", text: /Authorization/
    assert_select "code", text: /Bearer/
  end

  test "docs page includes endpoint documentation" do
    get api_docs_path
    assert_response :success
    assert_match "/api/v1/events", response.body
    assert_match "GET", response.body
    assert_match "POST", response.body
    assert_match "PATCH", response.body
    assert_match "DELETE", response.body
  end
end
