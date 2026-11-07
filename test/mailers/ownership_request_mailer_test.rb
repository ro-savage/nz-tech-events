require "test_helper"

class OwnershipRequestMailerTest < ActionMailer::TestCase
  test "new_request email is sent to the admin" do
    ownership_request = OwnershipRequest.create!(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "I now run this meetup."
    )
    admin = users(:admin)

    mail = OwnershipRequestMailer.new_request(ownership_request, admin)

    assert_equal [ admin.email_address ], mail.to
    assert_equal "New ownership request for #{ownership_request.event.title}", mail.subject
    assert_equal [ "rowan.savage@gmail.com" ], mail.reply_to
    assert_match ownership_request.requester.display_name, mail.body.encoded
    assert_match ownership_request.reason, mail.body.encoded
  end

  test "approved email is sent to the requester" do
    ownership_request = OwnershipRequest.create!(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "I now run this meetup."
    )
    ownership_request.approve!(users(:admin))

    mail = OwnershipRequestMailer.approved(ownership_request)

    assert_equal [ ownership_request.requester.email_address ], mail.to
    assert_equal "You now own #{ownership_request.event.title} on NZ Tech Events", mail.subject
    assert_equal [ "rowan.savage@gmail.com" ], mail.reply_to
    assert_match ownership_request.event.title, mail.body.encoded
    assert_match "approved", mail.body.encoded
  end

  # Regression: forcing content_type "text/html" on a mail with both html and
  # text templates mislabelled the multipart body, so clients showed raw MIME
  # boundaries ("----==_mimepart_...") at the top of the email.
  test "new_request and approved emails are multipart/alternative" do
    ownership_request = OwnershipRequest.create!(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "I now run this meetup."
    )

    new_request = OwnershipRequestMailer.new_request(ownership_request, users(:admin))
    ownership_request.approve!(users(:admin))
    approved = OwnershipRequestMailer.approved(ownership_request)

    [ new_request, approved ].each do |mail|
      assert_equal "multipart/alternative", mail.mime_type
      assert_equal %w[text/plain text/html], mail.parts.map(&:mime_type)
    end
  end
end
