require "test_helper"

class EventSearchTest < ActiveSupport::TestCase
  test "search scope matches title" do
    results = Event.search("Ruby")
    assert results.any? { |e| e.title.include?("Ruby") }
  end

  test "search scope matches short_summary" do
    results = Event.search("Ruby meetup")
    assert results.any? { |e| e.short_summary&.include?("Ruby") }
  end

  test "search scope with blank query returns all" do
    assert_equal Event.all.count, Event.search("").count
    assert_equal Event.all.count, Event.search(nil).count
  end

  test "search scope is case-insensitive" do
    upper_results = Event.search("RUBY")
    lower_results = Event.search("ruby")
    assert_equal upper_results.pluck(:id).sort, lower_results.pluck(:id).sort
    assert upper_results.any?
  end

  test "search scope returns no results for non-matching query" do
    results = Event.search("zzzznonexistentzzzz")
    assert_empty results
  end

  test "search scope can be chained with other scopes" do
    results = Event.approved.upcoming.search("Ruby")
    assert results.all?(&:approved?)
    assert results.all? { |e| e.start_date >= Date.current }
  end
end
