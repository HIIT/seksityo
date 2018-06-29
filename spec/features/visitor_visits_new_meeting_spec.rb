require 'rails_helper'

feature 'New meeting' do
  before :each do

  end
=begin
  scenario 'new user visits new meeting' do
    visit '/meetings/new'
    expect(page).to have_content("Please enter your phone number.")
  end
  scenario 'user with no credits visits new meeting' do
    u = User.create(phone_number: "9991231234")
    create_cookie('ucd', u.code)
    visit '/meetings/new'
    expect(page).to have_content("Out of credits!")
  end
=end
  scenario 'user visits new meeting' do
    allow(Meeting).to receive(:has_exceeded_max_total).and_return(false)
    u = User.create(phone_number: "9991231234")
    u.credits = 100
    u.save
    create_cookie('ucd', u.code)
    visit '/meetings/new'

    expect(page).to have_content("Artemis' Umbrella")
  end
  scenario 'user with existing meeting visits new meeting and gets redirected to status page', js: true do
    allow(Meeting).to receive(:has_exceeded_max_total).and_return(false)
    u = User.create(phone_number: "9991231234")
    u.credits = 100
    u.save
    create_cookie('ucd', u.code)
    visit '/'
    fill_in 'meeting_nickname', with: "Turbo"
    fill_in 'meeting_phone_number', with: '0401231234'
    fill_in 'duration-input', with: '3'
    click_button 'startbutton'
    visit '/meetings/new'

    expect(page).to have_content('Informing your Artemis in')
  end
end
