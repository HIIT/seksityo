class AdminsController < ApplicationController
  helper_method :sort_column, :sort_direction
  before_action :authenticate, :set_locale

  def index
    @month_stats = []
    @year_stats = []
    @impression_statuses = Impression.statuses
    first_date = Date.parse("1st June 2018")
    last_date = Date.today()
    date_range = first_date..last_date
    months = date_range.map {|date| Date.new(date.year, date.month, 1)}.uniq
    years = date_range.map {|year| Date.new(year.year, 1, 1)}.uniq
    months.each do |month|
      @month_stats += Impression.generate_stats(month.beginning_of_month, month.end_of_month)
    end
    years.each do |year|
      @year_stats += Impression.generate_stats(year.beginning_of_year, year.end_of_year)
    end

    # Fetch column name and direction from the parameters and pass them to order method.
    @statistics = Stat.order(stat_sort_column + " " + stat_sort_direction)

    @month_stats.sort_by!{|stat|  stat[impression_sort_column]}
    (impression_sort_direction == "desc") ? @month_stats : @month_stats.reverse!

    @year_stats.sort_by!{|stat|  stat[impression_sort_column]}
    (impression_sort_direction == "desc") ? @year_stats : @year_stats.reverse!

    # Either sort manually by time to live return value, or normally via column order.
    if meeting_sort_column == "time_to_live"
      @meetings = Meeting.all.sort { |a, b| a.time_to_live <=> b.time_to_live }
      if meeting_sort_direction == "desc"
        @meetings.reverse!
      end
    else
      @meetings = Meeting.order(meeting_sort_column + " " + meeting_sort_direction)
    end

    @users = User.all.order(user_sort_column + " " + user_sort_direction)

    render 'admins/index'
  end

  def month_stat
    month_start = params[:month]+ "-01"
    @day_stats = []
    @impression_statuses = Impression.statuses
    month_start = Date.strptime(month_start,"%Y-%m-%d")
    month_end = month_start.end_of_month
    date_range = month_start..month_end
    date_range.each do |day|
      @day_stats += Impression.generate_stats(day.beginning_of_day, day.end_of_day)
    end
    @day_stats.sort_by!{|stat|  stat[impression_sort_column]}
    (impression_sort_direction == "desc") ? @day_stats : @day_stats.reverse!
    render 'admins/month_stat'
  end

  def custom_stat
    @interval_start = params[:start]
    @interval_end = params[:end]
    @impression_statuses = Impression.statuses
    @custom_stats = Impression.generate_stats(@interval_start, @interval_end)
    @custom_stats.sort_by!{|stat|  stat[impression_sort_column]}
    (impression_sort_direction == "desc") ? @custom_stats : @custom_stats.reverse!
    render 'admins/custom_stat'

  end

  private

  # Methods for fetching sort-related parameters
  def sort_column model
    case model
    when 'stat'
      stat_sort_column
    when 'meeting'
      meeting_sort_column
    when 'user'
      user_sort_column
    when 'impression'
      impression_sort_column
    end
  end

  def sort_direction model
    case model
    when 'stat'
      stat_sort_direction
    when 'meeting'
      meeting_sort_direction
    when 'user'
      user_sort_direction
    when 'impression'
      impression_sort_direction
    end
  end

  # Only accept column name that exists for Stat. Default to country_code
  def stat_sort_column
    Stat.column_names.include?(params[:stat_sort]) ? params[:stat_sort] : "country"
  end
  # Only accept "asc" or "desc" as params for direction. Default to "asc".
  def stat_sort_direction
    %w[asc desc].include?(params[:stat_direction]) ? params[:stat_direction] : "asc"
  end

  # Check if time to live, otherwise check if existing column name
  def meeting_sort_column
    if params[:meeting_sort] == "time_to_live"
      return "time_to_live"
    end
    Meeting.column_names.include?(params[:meeting_sort]) ? params[:meeting_sort] : "created_at"
  end

  def meeting_sort_direction
    %w[asc desc].include?(params[:meeting_direction]) ? params[:meeting_direction] : "desc"
  end

  def user_sort_column
    User.column_names.include?(params[:user_sort]) ? params[:user_sort] : "credits"
  end

  def user_sort_direction
    %w[asc desc].include?(params[:user_direction]) ? params[:user_direction] : "asc"
  end

  def impression_sort_column
    column_names = ["country",  "date", "views", "created", "timers_stopped", "messages_sent", "alerts_sent", "notifications_sent", "messages_resent", "resent_messages_delivered", "location_percentage"] + Impression.statuses
    column_names.include?(params[:impression_sort]) ? params[:impression_sort] : "date"
  end

  def impression_sort_direction
    %w[asc desc].include?(params[:impression_direction]) ? params[:impression_direction] : "desc"
  end
  protected

end
