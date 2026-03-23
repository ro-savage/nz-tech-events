require "test_helper"

class MarkdownConverterTest < ActiveSupport::TestCase
  test "converts basic markdown to HTML" do
    result = MarkdownConverter.call("**bold** and *italic*")
    assert result.valid?
    assert_includes result.html, "<strong>bold</strong>"
    assert_includes result.html, "<em>italic</em>"
  end

  test "converts markdown links" do
    result = MarkdownConverter.call("[link](https://example.com)")
    assert result.valid?
    assert_includes result.html, '<a href="https://example.com">link</a>'
  end

  test "converts markdown lists" do
    result = MarkdownConverter.call("- item 1\n- item 2")
    assert result.valid?
    assert_includes result.html, "<li>item 1</li>"
  end

  test "converts plain text (no markdown)" do
    result = MarkdownConverter.call("Just some plain text")
    assert result.valid?
    assert_includes result.html, "Just some plain text"
  end

  test "strips raw HTML tags from input" do
    result = MarkdownConverter.call("Hello <script>alert('xss')</script> world")
    assert result.valid?
    assert_not_includes result.html, "<script>"
    assert_includes result.html, "world"
  end

  test "strips dangerous HTML but keeps markdown formatting" do
    result = MarkdownConverter.call("**bold** <img src=x onerror=alert(1)> text")
    assert result.valid?
    assert_includes result.html, "<strong>bold</strong>"
    assert_not_includes result.html, "<img"
  end

  test "sanitized_markdown strips HTML tags" do
    result = MarkdownConverter.call("Hello <script>alert('xss')</script> world")
    assert result.valid?
    assert_not_includes result.sanitized_markdown, "<script>"
    assert_includes result.sanitized_markdown, "Hello"
    assert_includes result.sanitized_markdown, "world"
  end

  test "sanitized_markdown strips img tags with event handlers" do
    result = MarkdownConverter.call("**bold** <img src=x onerror=alert(1)> text")
    assert result.valid?
    assert_not_includes result.sanitized_markdown, "<img"
    assert_not_includes result.sanitized_markdown, "onerror"
  end

  test "sanitized_markdown preserves plain markdown" do
    result = MarkdownConverter.call("**bold** and [link](https://example.com)")
    assert result.valid?
    assert_equal "**bold** and [link](https://example.com)", result.sanitized_markdown
  end

  test "invalid when input is blank" do
    result = MarkdownConverter.call("")
    assert_not result.valid?
    assert_equal "can't be blank", result.error
  end

  test "invalid when input is nil" do
    result = MarkdownConverter.call(nil)
    assert_not result.valid?
    assert_equal "can't be blank", result.error
  end

  test "handles multiline markdown" do
    markdown = "# Heading\n\nParagraph text.\n\n- List item"
    result = MarkdownConverter.call(markdown)
    assert result.valid?
    assert_includes result.html, "<h1>Heading</h1>"
    assert_includes result.html, "<p>Paragraph text.</p>"
  end

  test "converts code blocks" do
    result = MarkdownConverter.call("```ruby\nputs 'hello'\n```")
    assert result.valid?
    assert_includes result.html, "<code"
  end
end
