class MeetingsController < ApplicationController
  before_action :set_meeting, only: [:show, :edit, :update, :destroy]
  before_action :set_locale
  before_action :validate_user, only: [:create, :send_alert]
  before_action :authenticate, only: [:destroy]
  include UserHelper


  # GET /meetings/1
  # GET /meetings/1.json
  def show
    @meeting = Meeting.find_by_hashkey(cookies['curr_me'])
    unless @meeting
      redirect_to :root
      return
    end
    if @meeting.message_sent
      redirect_to :meetings_alert_confirm
    end
    @meeting.create_impression(request.session_options[:id], "view")
  end

  # GET /meetings/new
  def new
    unless user_exists
      redirect_to users_path
      return
    end
    # If user already has an active meeting, find it based on cookies.
    if cookies['curr_me']
      @meeting = Meeting.find_by_hashkey(cookies['curr_me'])
      if @meeting
        redirect_to('/meeting')
        return
      end
    end
    # New meeting
    unless user_has_credits
      redirect_to credits_path
      return
    end
    @meeting = Meeting.new
    @meeting.create_impression(request.session_options[:id], "view")
  end

  # POST /meetings
  # POST /meetings.json
  def create
    @meeting = Meeting.new(meeting_params)
    @meeting.parse_phone_number
    @meeting.create_hashkey
    @meeting.alert_sent = false
    cookies.permanent['nkn'] = @meeting.nickname
    cookies.permanent['pnmr'] = @meeting.phone_number

    respond_to do |format|
      if @meeting.save
        #Stat.increment_created(@meeting.get_country_code, @meeting.get_country)
        @meeting.create_impression(request.session_options[:id], "meeting_created")
        cookies.permanent['curr_me'] = @meeting.hashkey
        # Reserve one credit to for sending a notification
        decrease_credits
        # Runs send_notification once the timer runs out
        @meeting.delay(run_at: @meeting.time_to_live.minutes.from_now).send_notification(I18n.locale, request.session_options[:id])
        format.html { redirect_to '/meeting', notice: 'Meeting was successfully created.' }
        format.json { render :show, status: :created, location: @meeting }
      else
        format.html { render :new }
        format.json { render json: @meeting.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @meeting = Meeting.find_by_id(params[:id])
      @meeting.destroy
      flash[:notify] = t('meeting_delete_success')
      redirect_to :back
    else
      flash[:notify] = t('meeting_delete_fail')
      redirect_to :back
    end
  end


  # PATCH/PUT /meetings/1.json
  def update
    respond_to do |format|
      if @meeting.update(meeting_params)
        format.html { redirect_to '/meeting', notice: 'Meeting was successfully updated.' }
        format.json { render :show, status: :ok, location: @meeting }
      else
        format.html { redirect_to :root }
      end
    end
  end


  # POST /meetings/meeting_ok/
  def meeting_ok
    @meeting = Meeting.find_by_hashkey(cookies['curr_me'])
    if @meeting
      #Stat.increment_confirmed(@meeting.get_country_code, @meeting.get_country)
      @meeting.create_impression(request.session_options[:id], "meeting_ok")
      if @meeting.find_job or @meeting.alert_sent?
        increment_credits
      end
      @meeting.delete_job
      @meeting.destroy
      cookies.delete 'curr_me'
      cookies.delete 'attempted_update'
    end
    redirect_to root_path
  end


  # POST /meetings/send_alert/
  def send_alert
    @meeting = Meeting.find_by_hashkey(cookies['curr_me'])
    unless @meeting
      cookies.delete 'curr_me'
      cookies.delete 'attempted_update'
      redirect_to root_path
      return
    end
    if @meeting.message_sent
      redirect_to :meetings_alert_confirm
    end
    decrease_credits
    @meeting.send_alert(request.session_options[:id])
    #Stat.increment_alerts_sent(@meeting.get_country_code, @meeting.get_country)
    redirect_to :meetings_alert_confirm
  end


  # GET /meetings/id
  def exists
    if Meeting.exists?(id: params[:id])
      msg = {:meeting_exists => true}
      render :json => msg
    else
      msg = {:meeting_exists => false}
      render :json => msg
    end
  end

  # GET /meetings/alert_confirm
  def alert_confirm
    @meeting = Meeting.find_by_hashkey(cookies['curr_me'])
    if !@meeting
      cookies.delete 'curr_me'
      cookies.delete 'attempted_update'
      redirect_to root_path
    end
    @meeting.create_impression(request.session_options[:id], "view")
  end

  # POST /meetings/add_time
  def add_time
    @meeting = Meeting.find_by_hashkey(cookies['curr_me'])
    if @meeting
      job = @meeting.find_job
      if job
        @meeting.duration = @meeting.duration+10
        job.run_at = job.run_at + 10.minutes
        @meeting.save
        job.save
        @meeting.create_impression(request.session_options[:id], "time_added")
      end
    end
    redirect_to '/meeting'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_meeting
    @meeting = Meeting.find_by_hashkey(cookies['curr_me'])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def meeting_params
    params.require(:meeting).permit(:nickname, :phone_number, :duration, :confirmed, :latitude, :longitude)
  end

end
