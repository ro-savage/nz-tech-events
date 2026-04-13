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

    # Pico CSS served from CDN
    policy.style_src   :self, "https://cdn.jsdelivr.net"

    # Inline scripts use nonces; importmaps and reCAPTCHA need their origins
    policy.script_src  :self,
                       "https://www.google.com/recaptcha/",
                       "https://www.gstatic.com/recaptcha/",
                       "https://www.recaptcha.net/"

    # reCAPTCHA v2 renders in an iframe
    policy.frame_src   "https://www.google.com/recaptcha/",
                       "https://www.recaptcha.net/"

    # Turbo and Stimulus use same-origin fetch
    policy.connect_src :self
  end

  # Generate session nonces for permitted importmap and inline scripts.
  config.content_security_policy_nonce_generator =
    ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]
end
