class MarkdownConverter
  Result = Struct.new(:html, :sanitized_markdown, :error, keyword_init: true) do
    def valid?
      error.nil?
    end
  end

  RENDERER_OPTIONS = {
    filter_html: true,
    no_images: false,
    no_links: false,
    no_styles: true,
    safe_links_only: true,
    hard_wrap: true
  }.freeze

  MARKDOWN_OPTIONS = {
    autolink: true,
    fenced_code_blocks: true,
    strikethrough: true,
    tables: true,
    no_intra_emphasis: true,
    lax_spacing: true
  }.freeze

  def self.call(markdown_text)
    if markdown_text.blank?
      return Result.new(error: "can't be blank")
    end

    # Strip HTML tags from input before processing (defense-in-depth).
    # Redcarpet's filter_html handles this during rendering, but we also
    # sanitize the stored markdown so it's safe if returned to API clients.
    sanitized = ActionController::Base.helpers.strip_tags(markdown_text)

    # Create new instances per call — Redcarpet renderers are not thread-safe.
    renderer = Redcarpet::Render::HTML.new(**RENDERER_OPTIONS)
    markdown = Redcarpet::Markdown.new(renderer, **MARKDOWN_OPTIONS)

    html = markdown.render(sanitized).strip

    Result.new(html: html, sanitized_markdown: sanitized)
  end
end
