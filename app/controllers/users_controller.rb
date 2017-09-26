class UsersController < ApplicationController
  before_action :authenticate, only: :update

  # POST /users/
  def receive_phone
    @user = User.find_by_phone_number(user_params[:phone_number])
    if !@user
      create_user
    else
      @user.send_recovery_link(request.base_url)
      render 'users/sms_sent'
    end
  end

  def create_user
    cookies.delete 'ucd'
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        cookies.permanent['ucd'] = @user.code
        format.html { redirect_to :root, notice: 'A new user was successfully created.' }
        format.json { render 'meetings/new', status: :created}
      else
        format.html { render '/users/phone_form' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def recover_cookie
    @user = User.find_by_code(params['id'])

    if @user
      cookies.delete 'ucd'
      cookies.permanent['ucd'] = params['id']
    end
    redirect_to :root

  end
  def out_of_credits
    @user = User.find_by_code(cookies['ucd'])

    if @user && @user.credits < 1
        render 'out_of_credits'
        return
    end

    redirect_to :root
  end

  # GET /users/
  def phone_form
    @user = User.new
  end


  # PATCH/PUT /users/1.json
  def update
    @user = User.find params[:id]
    respond_to do |format|
      if @user.update(user_params)
        flash[:notify] = t('user_credits_update_success')
        format.html { redirect_to '/admin', notice: 'Credits were successfully edited.' }
        format.json { render 'admins/index', status: :ok}
      else
        flash[:notify] = t('user_credits_update_fail')
        format.html { redirect_to '/admin'}
      end
    end
  end


  private

  def user_params
    params.require(:user).permit(:code, :phone_number, :credits)
  end


end
