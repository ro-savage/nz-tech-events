# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.base_uri    :self
    policy.form_action :self

    # Prevent clickjacking by disallowing framing of this site
    policy.frame_ancestors :none

    # Pico CSS served from CDN
    policy.style_src   :self, "https://cdn.jsdelivr.net"

    # Inline scripts use nonces; reCAPTCHA needs its origins
    policy.script_src  :self,
                       "https://www.google.com/recaptcha/",
                       "https://www.gstatic.com/recaptcha/",
                       "https://www.recaptcha.net/"

    # reCAPTCHA v2 renders in an iframe
    policy.frame_src   "https://www.google.com/recaptcha/",
                       "https://www.recaptcha.net/"

    # Turbo/Stimulus use same-origin fetch; reCAPTCHA v3 makes background requests
    policy.connect_src :self,
                       "https://www.google.com/recaptcha/",
                       "https://www.recaptcha.net/"
  end

  # Cryptographically random nonce per request for inline script protection.
  config.content_security_policy_nonce_generator =
    ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Auto-add nonce to javascript_tag, javascript_include_tag,
  # javascript_importmap_tags, and stylesheet_link_tag.
  config.content_security_policy_nonce_auto = true
end
