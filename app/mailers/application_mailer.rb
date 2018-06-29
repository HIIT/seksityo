class ApplicationMailer < ActionMailer::Base
  default from: "artemisumbrella@gmail.com"

  def notification_email(meeting)
    @meeting = meeting
    mail(to: @meeting.phone_number+'@textmagic.com', subject: 'Duration of meeting has passed.')
  end

  def alert_email(meeting)
    @meeting = meeting
    mail(to: @meeting.phone_number+'@textmagic.com', subject: 'Alert, friend is in danger!')
  end

  def recovery_link_email(user, recovery_link)
    @user = user
    @recovery_link = recovery_link
    mail(to: @user.phone_number+'@textmagic.com', subject: "Link to Artemis' Umbrella!")
  end

  def daily_total_message_limit_exceeded_email()
    mail(to: "artemisumbrella@gmail.com", subject: "Too many messages have been sent today!")
  end
end
