require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "valid token can be created for approved organiser" do
    user = users(:organiser)
    token = ApiToken.new(user: user, name: "My Script")
    raw_token = token.generate_token_value
    assert token.save
    assert raw_token.start_with?("techevent_")
    assert_equal 42, raw_token.length  # "techevent_" (10) + 32 base58 chars
    assert token.token_digest.present?
  end

  test "requires user" do
    token = ApiToken.new(name: "Test")
    assert_not token.valid?
    assert_includes token.errors[:user], "must exist"
  end

  test "requires name" do
    token = ApiToken.new(user: users(:organiser))
    assert_not token.valid?
    assert_includes token.errors[:name], "can't be blank"
  end

  test "requires token_digest" do
    token = ApiToken.new(user: users(:organiser), name: "Test")
    assert_not token.valid?
    assert_includes token.errors[:token_digest], "can't be blank"
  end

  test "token_digest must be unique" do
    existing = api_tokens(:organiser_token)
    token = ApiToken.new(
      user: users(:organiser),
      name: "Duplicate",
      token_digest: existing.token_digest
    )
    assert_not token.valid?
    assert_includes token.errors[:token_digest], "has already been taken"
  end

  test "authenticate returns token for valid raw token" do
    raw = "techevent_testtoken1234567890abcdef"
    token = ApiToken.authenticate(raw)
    assert_not_nil token
    assert_equal api_tokens(:organiser_token), token
  end

  test "authenticate returns nil for invalid token" do
    assert_nil ApiToken.authenticate("techevent_invalidtoken")
  end

  test "authenticate returns nil for nil" do
    assert_nil ApiToken.authenticate(nil)
  end

  test "authenticate returns nil for empty string" do
    assert_nil ApiToken.authenticate("")
  end

  test "touch_last_used updates timestamp" do
    token = api_tokens(:organiser_token)
    original = token.last_used_at
    travel_to 2.minutes.from_now do
      token.touch_last_used!
      assert_not_equal original, token.reload.last_used_at
    end
  end

  test "touch_last_used skips if used less than a minute ago" do
    token = api_tokens(:organiser_token)
    token.update!(last_used_at: 30.seconds.ago)
    original = token.last_used_at
    token.touch_last_used!
    assert_equal original, token.reload.last_used_at
  end

  test "user must be approved organiser or admin" do
    regular = users(:regular)
    token = ApiToken.new(user: regular, name: "Test")
    token.generate_token_value
    assert_not token.valid?
    assert_includes token.errors[:user], "must be an approved organiser or admin"
  end

  test "admin can create token" do
    admin = users(:admin)
    token = ApiToken.new(user: admin, name: "Admin Script")
    token.generate_token_value
    assert token.valid?
  end
end
