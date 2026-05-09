require "test_helper"

class SearchRequestTest < ActionDispatch::IntegrationTest
  test "GET /search with no query shows empty state" do
    get search_path
    assert_response :success
    assert_select "p", text: "Enter a search term to find upcoming events."
  end

  test "GET /search with blank query shows empty state" do
    get search_path, params: { q: "  " }
    assert_response :success
    assert_select "p", text: "Enter a search term to find upcoming events."
  end

  test "GET /search?q=Ruby finds events with Ruby in title" do
    get search_path, params: { q: "Ruby" }
    assert_response :success
    assert_select ".event-card-title", text: /Ruby/
  end

  test "GET /search?q=nonexistent returns no results" do
    get search_path, params: { q: "nonexistent" }
    assert_response :success
    assert_select "p", text: /No events found for/
  end

  test "search only returns approved events" do
    get search_path, params: { q: "Hackathon" }
    assert_response :success
    # The unapproved "Startup Hackathon" fixture should not appear
    assert_select ".event-card-title", { text: /Hackathon/, count: 0 }
  end

  test "search only returns upcoming events" do
    get search_path, params: { q: "Conference" }
    assert_response :success
    # The past "NZ Tech Conference 2025" fixture should not appear
    assert_select ".event-card-title", { text: /NZ Tech Conference/, count: 0 }
  end

  test "search is case-insensitive" do
    get search_path, params: { q: "ruby" }
    assert_response :success
    assert_select ".event-card-title", text: /Ruby/
  end

  test "search form is present on search page" do
    get search_path
    assert_response :success
    assert_select "form[action='#{search_path}']"
    assert_select "input[name='q']"
  end

  test "search displays result count" do
    get search_path, params: { q: "Ruby" }
    assert_response :success
    assert_select "p", text: /event.*found for/
  end
end
