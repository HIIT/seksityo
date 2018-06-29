require 'rails_helper'

feature 'Root redirection' do
  scenario 'existing user with credits visits root' do
    allow(Meeting).to receive(:has_exceeded_max_total).and_return(false)
    u = User.create(phone_number: "9991231234")
    u.credits = 100
    u.save
    create_cookie('ucd', u.code)
    visit '/'

    expect(page).to have_content("Artemis' Umbrella")
  end
=begin
  scenario 'existing user without credits visits root' do
    u = User.create(phone_number: "9991231234")
    create_cookie('ucd', u.code)
    visit '/'

    expect(page).to have_content("Out of credits!")
  end
  scenario 'new user visits root' do
    visit '/'
    expect(page).to have_content("Please enter your phone number.")
  end
=end
end
