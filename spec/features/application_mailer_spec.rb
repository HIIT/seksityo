require 'rails_helper'

describe 'Mailer' do
=begin
  before :each do
    clear_emails
    Delayed::Worker.delay_jobs = false
    u = User.create(phone_number: "9991231234")
    u.credits = 100
    u.save
    create_cookie('ucd', u.code)
    visit '/meetings/new'
    fill_in 'meeting_nickname', with: 'Pekka'
    fill_in 'duration-input', with: '1'
    fill_in 'meeting_phone_number', with: '0401231234'
  end

  after :each do
    Delayed::Worker.delay_jobs = true
  end

  it 'should send message when the timer goes off', js: true do
    click_button 'startbutton'
    sleep(0.3)
    open_email('0401231234@textmagic.com')
    expect(current_email).to have_content "Timed message from"
  end
  it 'should send the email to the address specified by user', js: true do
    click_button 'startbutton'
    sleep(0.3)
    open_email('0501231234@textmagic.com')
    expect(current_email).to be(nil)
  end
=end

  it 'should send message when daily total message limit is exceeded', js:true do
    Meeting.stub(:max_total_per_day) {0}
    allow(Meeting).to receive(:send_message).and_return(1)
    allow(Meeting).to receive(:update_status).and_return("-")
    clear_emails
    Delayed::Worker.delay_jobs = false

    u = User.create(phone_number: "9991231234")
    u.credits = 100
    u.save
    create_cookie('ucd', u.code)
    visit '/meetings/new'
    sleep(0.3)

    open_email('artemisumbrella@gmail.com')
    expect(current_email).to have_content "Daily total messages limit exceeded."
    Delayed::Worker.delay_jobs = true
  end
end
