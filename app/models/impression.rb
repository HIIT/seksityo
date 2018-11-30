class Impression < ActiveRecord::Base
  def self.countries()
    return Impression.where.not(:impression_type => "cleared_obsolete_meetings").distinct.pluck(:country, :country_code)
  end
  def self.round(number)
    if number.to_f.nan?
      return -1
    end
    return (number * 100.0).round / 100.0
  end
  def self.in_country_during_interval(country_code, interval_start, interval_end)
    return Impression.where(:country_code => country_code, :created_at => (interval_start..interval_end))
  end
  def self.message_sent()
    return Impression.where(:impression_type => "alert_sent").or(Impression.where(:impression_type => "notification_sent"))
  end
  def self.messages_sent_in_country_during_interval(country_code, interval_start, interval_end)
    return message_sent().merge(in_country_during_interval(country_code, interval_start, interval_end))
  end
  def self.statuses()
    return Impression.where(:impression_type => "alert_sent").or(Impression.where(:impression_type => "notification_sent")).distinct.pluck(:status)
  end
  def self.location_percentage(country_code, interval_start, interval_end)
    total = messages_sent_in_country_during_interval(country_code, interval_start, interval_end)
    with_location = total.where.not(:latitude => nil)
    return round(with_location.count.to_f/total.count * 100)
  end
  def self.status_percentages(country_code, interval_start, interval_end)
    messages = messages_sent_in_country_during_interval(country_code, interval_start, interval_end)
    total = messages.count
    percentages = {}
    for status in statuses() do
      percentages[status] = round(messages.where(:status => status).count.to_f / total * 100)
    end
    return percentages
  end
  def self.generate_stats(interval_start, interval_end)
    stats = []
    for country in countries do
      stat = {}
      stat["country"] = country[0].to_s + " (" + country[1].to_s + ")"
      if country[0].nil?
        stat["country"] = I18n.t('no_meetings_created')
      end
      if interval_start.to_date == interval_end.to_date
        stat["date"] = interval_start.to_date
      elsif interval_start.to_date.year == interval_end.to_date.year && interval_start.to_date.month == interval_end.to_date.month
        stat["date"] = interval_start.to_date.strftime("%Y-%m")
      elsif interval_start.to_date.year == interval_end.to_date.year
        stat["date"] = interval_start.to_date.strftime("%Y")
      else
        stat["date"] = interval_start.to_date.to_s + " - " + interval_end.to_date.to_s
      end
      impressions = in_country_during_interval(country[1], interval_start, interval_end)
      stat["views"] = impressions.where(:impression_type => "view").distinct.pluck(:session).count
      stat["created"] = impressions.where(:impression_type => "meeting_created").count
      stat["confirmed"] = impressions.where(:impression_type => "meeting_ok").count
      stat["messages_sent"] = messages_sent_in_country_during_interval(country[1], interval_start, interval_end).count
      stat["timers_stopped"] = stat["created"] - stat["messages_sent"]
      stat["alerts_sent"] = impressions.where(:impression_type => "alert_sent").count
      stat["messages_resent"] = impressions.where(:impression_type => "message_resent").count
      stat["resent_messages_delivered"] = impressions.where(:impression_type => "message_resent", :status => "d").count
      stat["notifications_sent"] = impressions.where(:impression_type => "notification_sent").count
      stat["location_percentage"] = location_percentage(country[1], interval_start, interval_end)
      stat= stat.merge(status_percentages(country[1], interval_start, interval_end))
      stats.push(stat)
    end
    return stats
  end

end
