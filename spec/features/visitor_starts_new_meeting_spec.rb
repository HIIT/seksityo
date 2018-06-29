require 'rails_helper'

feature 'When starting a new meeting' do
  before :each do
    u = User.create(phone_number: "9991231234")
    u.credits = 100
    u.save
    create_cookie('ucd', u.code)
    allow(Meeting).to receive(:has_exceeded_max_total).and_return(false)
  end

  scenario 'user can create a meeting', js: true do
    visit '/meetings/new'
    fill_in 'meeting_nickname', with: 'Pekka'
    fill_in 'meeting_phone_number', with: '0401231234'
    fill_in 'duration-input', with: '11'
    click_button 'startbutton'

    expect(page).to have_content('Informing your Artemis in')
  end
  scenario 'user cannot create a meeting with an incorrect phone number', js:true do
    visit '/meetings/new'
    fill_in 'meeting_nickname', with: 'Pekka'
    fill_in 'meeting_phone_number', with: '99999999999'
    fill_in 'duration-input', with: '111'
    click_button 'startbutton'

    expect(page).to have_content('Phone number is invalid')

    fill_in 'meeting_nickname', with: 'Pekka'
    fill_in 'meeting_phone_number', with: 'asd'
    fill_in 'duration-input', with: '111'
    click_button 'startbutton'

    expect(page).to have_content('Phone number is invalid')

    fill_in 'meeting_nickname', with: 'Pekka'
    fill_in 'meeting_phone_number', with: '040123'
    fill_in 'duration-input', with: '111'
    click_button 'startbutton'

    expect(page).to have_content('Phone number is invalid')
  end
  scenario 'user can create a meeting with a kenyan phone number', js:true do
    visit '/meetings/new'
    fill_in 'meeting_nickname', with: 'Pekka'
    fill_in 'meeting_phone_number', with: '+2541231234'
    fill_in 'duration-input', with: '11'
    click_button 'startbutton'

    expect(page).to have_content('Informing your Artemis in')
  end
  scenario 'user sees manually input duration on status page', js: true do
    visit '/meetings/new'
    fill_in 'meeting_nickname', with: 'Matti'
    fill_in 'meeting_phone_number', with: '0401231234'
    fill_in 'duration-input', with: '5'
    click_button 'startbutton'

    expect(page).to have_content('5 minutes')
  end
  # scenario 'user sees selected 2h duration on status page', js: true do
  #   visit '/meetings/new'
  #   fill_in 'meeting_nickname', with: 'Sami'
  #   fill_in 'meeting_phone_number', with: '0401231234'
  #   find('#select2h').click
  #   click_button 'startbutton'
  #   expect(page).to have_content('120 minutes')
  # end
  scenario 'user sees selected 1h duration on status page', js: true do
    visit '/meetings/new'
    fill_in 'meeting_nickname', with: 'Jyrki'
    fill_in 'meeting_phone_number', with: '0401231234'
    find('#select1h').click
    click_button 'startbutton'
    expect(page).to have_content('60 minutes')
  end
  scenario 'user sees selected 30min duration on status page', js: true do
    visit '/meetings/new'
    fill_in 'meeting_nickname', with: 'Hilla'
    fill_in 'meeting_phone_number', with: '0401231234'
    find('#select30m').click
    click_button 'startbutton'
    expect(page).to have_content('30 minutes')
  end
  scenario 'user selects duration and then manually enters one', js: true do
    visit '/meetings/new'
    fill_in 'meeting_nickname', with: 'Tatti'
    fill_in 'meeting_phone_number', with: '0401231234'
    find('#select30m').click
    fill_in 'duration-input', with: '12'
    click_button 'startbutton'
    expect(page).to have_content('12 minutes')
  end
  scenario 'user manually enters duration and then selects one', js: true do
    visit '/meetings/new'
    fill_in 'meeting_nickname', with: 'Laura'
    fill_in 'meeting_phone_number', with: '0401231234'
    fill_in 'duration-input', with: '75'
    find('#select30m').click
    click_button 'startbutton'
    expect(page).to have_content('30 minutes')
  end
end
