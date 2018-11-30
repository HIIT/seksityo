class Meeting < ActiveRecord::Base
  validates :duration, numericality: { greater_than: 0,
                                       only_integer: true,
                                       less_than: 1440 }, allow_blank: false

  validate :validate_phone_number
  require 'delayed_job'

  def self.max_per_user_per_day
    20
  end

  def self.max_total_per_day
    1000
  end

  def self.resend_delay
    5.minutes
  end

  def time_to_live
    time = Time.new
    minutes = (((self.created_at + (self.duration * 60)) - time)/60)

    # Only round minutes if the value is higher than 1
    unless minutes.between?(0,1)
      minutes = minutes.round
    end

    if minutes < 0
      minutes = 0
    end

    return minutes
  end

  def create_hashkey
    self.hashkey = Digest::SHA2.new(512).hexdigest(self.nickname + self.phone_number + Time.now.to_s)
  end

  def send_notification(locale, session_hash, textmagic_username, textmagic_password)
    unless self.alert_sent?
      I18n.locale = locale
      #Old way of doing things
      #ApplicationMailer.notification_email(self).deliver_now
      #Stat.increment_notifications_sent(self.get_country_code, self.get_country)

      #Piece together the message
      message = I18n.t('notification_message_from') + " " + self.nickname.upcase + "! " + I18n.t('notification_message_text') + " "
      if (self.latitude && self.longitude)
        message += I18n.t('message_location')+ " http://maps.google.com/maps?z=12&t=m&q=loc:"+self.latitude+"+"+self.longitude
      else
        message += I18n.t('message_location_unavailable')
      end
      #Keep the impression so that we can update the status later on
      impression = create_impression(session_hash, "notification_sent")
      #Send the message via the API
      id = Meeting.send_message(message, textmagic_username, textmagic_password, self.phone_number)
      #Resend the message if need be, otherwise update the status
      Meeting.delay(run_at: Meeting.resend_delay.from_now).resend_if_needed(id, message, impression, textmagic_username, textmagic_password, session_hash, self.phone_number, self.get_country_code, self.get_country)
    end
  end

  def send_alert(session_hash)
    unless self.message_sent
      self.update(alert_sent: true)
      #Keep the impression so that we can update the status later on
      impression = create_impression(session_hash, "alert_sent")
      #Send via email
      #ApplicationMailer.alert_email(self).deliver_now

      #Piece together the alert message
      message = self.nickname.upcase + " " + I18n.t('alert_message_text') + " "
      if (self.latitude && self.longitude)
        message += I18n.t('message_location')+ " http://maps.google.com/maps?z=12&t=m&q=loc:"+self.latitude+"+"+self.longitude
      else
        message += I18n.t('message_location_unavailable')
      end
      #Send via API
      id = Meeting.send_message(message, ENV["TEXTMAGIC_USERNAME"], ENV["TEXTMAGIC_PASSWORD"], self.phone_number)
      #Resend if needed, otherwise update impression status
      Meeting.delay(run_at: Meeting.resend_delay.from_now).resend_if_needed(id, message, impression, ENV["TEXTMAGIC_USERNAME"], ENV["TEXTMAGIC_PASSWORD"], session_hash, self.phone_number, self.get_country_code, self.get_country)
    end
  end

  def create_impression(session_hash, type, status="u")
    #Update view country codes
    if type=="view" && Impression.exists?(session:session_hash, impression_type:type) && !self.get_country_code.blank?
      for impression in Impression.where(:session => session_hash, :impression_type => type, :country_code => nil) do
        impression.country_code = self.get_country_code
        impression.country = self.get_country
        impression.save
      end
    end

    impression = Impression.new impression_type:type, session:session_hash, country_code:self.get_country_code, country:self.get_country, status:status
    unless self.latitude.nil?
      #Rounded a little for privacy's sake - that way we don't keep the exact location, only the general area
      impression.latitude = ((self.latitude.to_f*100.0).round / 100.0).to_s
      impression.longitude = ((self.longitude.to_f*100.0).round / 100.0).to_s
    end
    #Update country code based on previous ones if not available otherwise
    country = Impression.where(:session => session_hash).where.not(:country_code => nil).distinct.pluck(:country_code, :country).last
    if self.get_country_code.nil? && !country.nil?
      impression.country_code = country[0]
      impression.country = country[1]
    end
    impression.save
    return impression
  end

  def validate_phone_number
    phone = Phonelib.parse(self.phone_number)
    unless self.phone_number == '9991231234' or phone.valid?
      errors.add(:phone_number, "Phone number is invalid.")
    end
    if self.phone_number[0] == "0"
      errors.add(:phone_number, "Country code missing.")
    end
  end

  def parse_phone_number
    phone = Phonelib.parse(self.phone_number)
    self.phone_number = phone.sanitized
  end

  def delete_job()
    job = find_job()
    if job
      job.delete
    end
  end

  def find_job()
    jobs = Delayed::Job.all
    found_job = nil
    jobs.each do |job|
      meeting = YAML::load(job.handler)
      if meeting.method_name == :send_notification && meeting.hashkey.match(hashkey)
        found_job = job
      end
    end
    found_job
  end

  def get_country_code()
    phone = Phonelib.parse(self.phone_number)
    return phone.country_code
  end

  def get_country()
    phone = Phonelib.parse(self.phone_number)
    return phone.country
  end

  def message_sent()
    return (self.alert_sent? or self.time_to_live==0)
  end

  def self.has_exceeded_max_total()
    alerts = Impression.where(:impression_type => 'alert_sent', :created_at => (Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)).count
    notifications = Impression.where(:impression_type => 'notification_sent', :created_at => (Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)).count
    total_messages = alerts + notifications
    exceeded_today = (total_messages >= Meeting.max_total_per_day)
    exceeded_before = Impression.where(:created_at => Time.zone.now.beginning_of_day..Time.zone.now.end_of_day, :impression_type => "max_total_exceeded").exists?
    if exceeded_today && !exceeded_before
      Meeting.send_message("Max limit exceeded!", ENV["TEXTMAGIC_USERNAME"], ENV["TEXTMAGIC_PASSWORD"], Phonelib.parse(ENV["EMERGENCY_CONTACT_NUMBER"]).sanitized)
      ApplicationMailer.daily_total_message_limit_exceeded_email().deliver_now()
      impression = Impression.new impression_type:"max_total_exceeded"
      impression.save()
    end
    return exceeded_today
  end

  def self.clear_obsolete()
    if Impression.where(:created_at => Time.zone.now.beginning_of_day..Time.zone.now.end_of_day, :impression_type =>"cleared_obsolete_meetings").exists?
      return
    end
    impression = Impression.new impression_type:"cleared_obsolete_meetings"
    impression.save
    meetings = Meeting.all
    for meeting in meetings do
      if meeting.time_to_live == 0
        meeting.delay(run_at: 60.minutes.from_now).destroy()
      end
    end
  end

  def self.send_message(message, username, password, phone_number)
    api = TextMagic::API.new(username, password)
    id = api.send(message, phone_number)
    return id
  end

  def self.update_status(id, impression, username, password)
    api = TextMagic::API.new(username, password)
    status = api.message_status(id)
    impression.status = status
    impression.save
    return status
  end

  def self.resend_if_needed(id, message, impression, username, password, session_hash, phone_number, country_code, country)
    status = Meeting.update_status(id, impression, username, password)
    unless status == "d"
      #Do not bother resending test messages
      if country_code == "999"
        return
      end
      impression = Impression.new impression_type:"message_resent", session:session_hash, country_code:country_code, country:country
      #create_impression(session_hash, "message_resent")
      impression.save
      #The message hasn't been delivered. Attempt to resend it once
      id = Meeting.send_message(message,  username, password, phone_number)
      #Update status once the message is (hopefully) delivered.
      Meeting.delay(run_at: Meeting.resend_delay.from_now).update_status(id, impression, username, password)
    end
  end
end
