require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "responses include Content-Security-Policy header" do
    get root_path
    assert_response :success
    assert response.headers["Content-Security-Policy"].present?,
      "Expected Content-Security-Policy header to be present"
  end

  test "CSP header includes default-src self" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    assert_match(/default-src 'self'/, csp)
  end

  test "CSP header includes script-src with nonce" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    assert_match(/script-src 'self'/, csp)
    assert_match(/nonce-/, csp)
  end

  test "CSP header allows Pico CSS CDN in style-src" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    assert_match(/style-src 'self' https:\/\/cdn\.jsdelivr\.net/, csp)
  end

  test "CSP header allows reCAPTCHA in script-src and frame-src" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    assert_match(/script-src.*www\.google\.com\/recaptcha/, csp)
    assert_match(/frame-src.*www\.google\.com\/recaptcha/, csp)
  end

  test "CSP header blocks object embeds" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    assert_match(/object-src 'none'/, csp)
  end

  test "CSP header restricts form-action to self" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    assert_match(/form-action 'self'/, csp)
  end

  test "CSP header prevents clickjacking with frame-ancestors none" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    assert_match(/frame-ancestors 'none'/, csp)
  end

  test "CSP nonce changes between requests" do
    get root_path
    csp1 = response.headers["Content-Security-Policy"]
    nonce1 = csp1[/nonce-([A-Za-z0-9+\/=]+)/, 1]

    get root_path
    csp2 = response.headers["Content-Security-Policy"]
    nonce2 = csp2[/nonce-([A-Za-z0-9+\/=]+)/, 1]

    assert_not_equal nonce1, nonce2,
      "Nonce must be unique per request for CSP security"
  end

  test "CSP header allows reCAPTCHA in connect-src" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    assert_match(/connect-src.*www\.google\.com\/recaptcha/, csp)
  end

  test "inline scripts in layout include nonce attribute" do
    get root_path
    assert_match(/script nonce="[^"]*"/, response.body)
  end

  test "no inline onclick handlers in layout" do
    get root_path
    assert_no_match(/onclick=/, response.body)
  end

  test "event form inline scripts include nonce attribute" do
    sign_in_as users(:regular)
    get new_event_path
    assert_response :success
    assert_match(/script.*nonce="[^"]*"/, response.body)
    assert_no_match(/onclick=/, response.body)
  end
end
