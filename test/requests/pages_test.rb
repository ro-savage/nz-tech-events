require "test_helper"

class PagesRequestTest < ActionDispatch::IntegrationTest
  test "GET /about returns 200" do
    get about_path
    assert_response :success
  end
end
