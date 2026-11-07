require "test_helper"

# Guards against the bug where a mailer forced `content_type: "text/html"` on an
# email that also had a .text.erb template: the multipart body was mislabelled
# as plain HTML, so clients showed raw "----==_mimepart_..." boundaries.
#
# Renders every email the app sends and checks its top-level Content-Type
# matches its actual structure.
class EmailFormatTest < ActionMailer::TestCase
  def emails
    ownership_request = OwnershipRequest.create!(
      event: events(:approved_upcoming),
      requester: users(:organiser),
      reason: "I now run this meetup."
    )

    {
      "AdminMailer#pending_events_reminder" => -> { AdminMailer.pending_events_reminder(users(:admin), 2) },
      "EventMailer#approved" => -> { EventMailer.approved(events(:approved_upcoming)) },
      "OwnershipRequestMailer#new_request" => -> { OwnershipRequestMailer.new_request(ownership_request, users(:admin)) },
      "OwnershipRequestMailer#approved" => -> { OwnershipRequestMailer.approved(ownership_request) },
      "PasswordsMailer#reset" => -> { PasswordsMailer.reset(users(:regular)) },
      "UserMailer#approved_organiser" => -> { UserMailer.approved_organiser(users(:regular)) },
      "WeeklyDigestMailer#digest" => -> {
        WeeklyDigestMailer.digest(
          email_subscriptions(:wellington_sub),
          [ events(:approved_upcoming) ],
          [ events(:approved_upcoming), events(:free_event) ],
          [ events(:paid_event) ]
        )
      }
    }
  end

  test "every mailer action is covered" do
    Rails.application.eager_load!
    actual = ApplicationMailer.descendants.flat_map do |mailer|
      mailer.action_methods.map { |action| "#{mailer.name}##{action}" }
    end

    assert_equal actual.sort, emails.keys.sort,
      "Add new mailer actions to EmailFormatTest#emails so their format is checked"
  end

  test "every email's Content-Type matches its structure" do
    emails.each do |name, build|
      mail = build.call

      # Check parts directly: mail.multipart? only reads the (possibly wrong) header.
      if mail.parts.any?
        assert_equal "multipart/alternative", mail.mime_type, "#{name} has parts but is labelled #{mail.mime_type}"
        assert_equal %w[text/plain text/html], mail.parts.map(&:mime_type), "#{name} has unexpected parts"
      else
        assert_equal "text/html", mail.mime_type, "#{name} is not HTML"
        assert_no_match(/==_mimepart_/, mail.encoded, "#{name} body contains raw MIME boundaries")
      end
    end
  end
end
