class Meeting < ActiveRecord::Base
  validates :duration, numericality: { greater_than: 0,
                                       only_integer: true,
                                       less_than: 1440 }, allow_blank: false

  validate :validate_phone_number

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

  def send_notification(locale)
    unless self.alert_sent?
      I18n.locale = locale
      ApplicationMailer.notification_email(self).deliver_now
      Stat.increment_notifications_sent(self.get_country_code, self.get_country)
    end
  end

  def send_alert
    unless self.message_sent
      self.update(alert_sent: true)
      ApplicationMailer.alert_email(self).deliver_now
    end
  end

  def validate_phone_number
    phone = Phonelib.parse(self.phone_number)
    unless self.phone_number == '9991231234' or phone.valid?
      errors.add(:phone_number, "Phone number is invalid.")
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
      if meeting.hashkey.match(hashkey)
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
end
