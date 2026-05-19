require "test_helper"

class PagesRequestTest < ActionDispatch::IntegrationTest
  test "GET /about returns 200" do
    get about_path
    assert_response :success
  end

  test "GET /about renders Contributors section" do
    get about_path
    assert_response :success
    assert_select "h2", text: "Contributors"
    assert_select "a[href=?]", "https://github.com/olitreadwell", text: "Oli"
  end
end
