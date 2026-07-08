# frozen_string_literal: true

# Generates a dynamic XML sitemap for search engine crawlers.
# Lists all public pages and approved events.
class SitemapsController < ApplicationController
  # @route GET /sitemap.xml
  # @returns XML sitemap document
  def index
    @events = Event.approved.upcoming.select(:id, :updated_at)

    expires_in 1.hour, public: true
    fresh_when(etag: sitemap_cache_key)
  end

  private

  # @returns [String] cache key based on latest event update
  def sitemap_cache_key
    latest = @events.maximum(:updated_at)&.to_i || 0
    "sitemap/#{@events.size}/#{latest}"
  end
end
