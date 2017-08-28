require 'rails_helper'

RSpec.describe MeetingsController, type: :controller do
  before :each do
    u = User.create({phone_number: "9991231234"})
    u.credits = 100
    u.save
    @request.cookies['ucd'] = u.code
  end
  describe "GET show" do
    it "renders the show template" do
      Meeting.create(nickname: "Matti", phone_number: "0401231234", duration: 20)
      get :show, id: 1
      expect(response).to render_template("show")
    end
    it "redirects to root if no meeting found" do
      Meeting.create(nickname: "Matti", phone_number: "0401231234", duration: 20)
      @request.cookies['curr_me'] = "randomvalue"
      get :show, id: 123
      expect(response).to redirect_to(:root)
    end
  end
  describe "GET alert_confirm" do
    it "renders the alert confirmation template" do
      @meeting = Meeting.create(nickname: "Matti", phone_number: "9991231234", duration: 42)
      @meeting.create_hashkey
      @request.cookies['curr_me'] = @meeting.hashkey
      @meeting.save
      get :alert_confirm
      expect(response).to render_template("alert_confirm")
    end
    it "redirects to root if cookie is incorrect" do
      Meeting.create(nickname: "Matti", phone_number: "9991231234", duration: 42)
      @request.cookies['curr_me'] = "Even incorrect cookies are tasty."
      get :alert_confirm
      expect(response).to redirect_to("/")
    end
  end
  describe "GET new" do
    it "renders the new template" do
      get :new
      expect(response).to render_template("new")
    end
=begin
    it "redirects to phone input if no user" do
      @request.cookies['ucd'] = ""
      get :new
      expect(response).to redirect_to("/users")
    end
    it "redirects to out of credits page if no credits" do
      u = User.find_by_code(@request.cookies['ucd'])
      u.credits = 0
      u.save
      get :new
      expect(response).to redirect_to("/credits")
    end
=end
    context "with render views" do
      render_views

      it "renders the default localization if none is set" do
        get :new
        expect(response.body).to have_content("Artemis' Umbrella")
      end
      it "renders finnish localization if it is set" do
        @request.env['HTTP_ACCEPT_LANGUAGE'] = "fi"
        get :new
        expect(response.body).to have_content("Artemiksen Sateenvarjo")
      end
      it "renders default localization if headers contain unavailable localization" do
        @request.env['HTTP_ACCEPT_LANGUAGE'] = "fr"
        get :new
        expect(response.body).to have_content("Artemis' Umbrella")
      end
      it "render page in english if cookie is present" do
        @request.env['HTTP_ACCEPT_LANGUAGE'] = "fi"
        @request.cookies['lang'] = "en"
        get :new
        expect(response.body).to have_content("Artemis' Umbrella")
      end
      it "has language switching link in correct language based on http headers" do
        @request.env['HTTP_ACCEPT_LANGUAGE'] = "fi"
        @request.cookies['lang'] = "en"
        get :new
        expect(response.body).to have_content("Suomeksi")
      end
      it "has no language selector if localized language is not available" do
        @request.env['HTTP_ACCEPT_LANGUAGE'] = "fr"
        get :new
        expect(response.body).to_not  have_content("English")
      end
      it "has no language selector if preferred language is the default language" do
        @request.env['HTTP_ACCEPT_LANGUAGE'] = "en"
        get :new
        expect(response.body).to_not have_content("English")
      end
    end
    it "renders status page if hash found in cookies and database" do
      @meeting = Meeting.create(nickname: "Matti", phone_number: "0401231234", duration: 20)
      @meeting.create_hashkey
      @request.cookies['curr_me'] = @meeting.hashkey
      @meeting.save
      get :new
      expect(response).to redirect_to('/meeting')
    end
  end
  describe "POST create" do
=begin
    it "should redirect to phone input if no user" do
      @request.cookies['ucd'] = ""
      meeting_params = {:nickname => "Pekka", :phone_number => "0401231234", :duration => 30}
      post :create, :meeting => meeting_params
      expect(response).to redirect_to("/users")
    end
    it "should redirect to out of credits page if no credits" do
      u = User.find_by_code(@request.cookies['ucd'])
      u.credits = 0
      u.save
      meeting_params = {:nickname => "Pekka", :phone_number => "0401231234", :duration => 30}
      post :create, :meeting => meeting_params
      expect(response).to redirect_to("/credits")
    end
=end
    it "should create new meeting with correct params" do
        meeting_params = {:nickname => "Pekka", :phone_number => "0401231234", :duration => 30}
        expect { post :create, :meeting => meeting_params }.to change(Meeting, :count).by(1)
    end
=begin
    it "should cost one credit to create the meeting" do
      meeting_params = {:nickname => "Pekka", :phone_number => "0401231234", :duration => 30}
      expect { post :create, :meeting => meeting_params }.to change{User.find_by_code(@request.cookies['ucd']).credits}.by(-1)
    end
=end
    it "should not create new meeting with negative duration" do
      meeting_params = {:nickname => "Pekka", :phone_number => "0401231234", :duration => -1}
      expect { post :create, :meeting => meeting_params }.to change(Meeting, :count).by(0)
    end
    it "should not create new meeting with duration over 24h" do
      meeting_params = {:nickname => "Pekka", :phone_number => "0401231234", :duration => 1440}
      expect { post :create, :meeting => meeting_params }.to change(Meeting, :count).by(0)
    end
    it "should not create new meeting with string input duration" do
      meeting_params = {:nickname => "Pekka", :phone_number => "0401231234", :duration => "sdfd"}
      expect { post :create, :meeting => meeting_params }.to change(Meeting, :count).by(0)
    end
    it "should not create new meeting with invalid phone number" do
      meeting_params = {:nickname => "Pekka", :phone_number => "123", :duration => 30}
      expect { post :create, :meeting => meeting_params }.to change(Meeting, :count).by(0)
    end
    it "should create a delayed job" do
      meeting_params = {:nickname => "DelayedForEver", :phone_number => "0401231234", :duration => "1"}
      expect {post :create, :meeting => meeting_params}.to change {Delayed::Job.count}.by(1)
    end
    it "should run the delayed job" do
      meeting_params = {:nickname => "BackgroundProcessed", :phone_number => "0401231234", :duration => "1"}
      Delayed::Worker.delay_jobs = false
      expect {post :create, :meeting => meeting_params}.to change {Delayed::Job.count}.by(0)
      Delayed::Worker.delay_jobs = true
    end
  end
  describe "PUT update" do
    it "should update Meeting" do
      attr = { :nickname => "Pekka"}
      @meeting = Meeting.create(nickname: "Matti", phone_number: "0401231234", duration: 20)
      put :update, id: @meeting.id, :meeting => attr
      @meeting.reload
      expect(@meeting.nickname).to eq("Pekka")
      expect(response).to redirect_to('/meeting')
    end
    it "should not update invalid meeting" do
      attr = { :duration => -23}
      @meeting = Meeting.create(nickname: "Matti", phone_number: "0401231234", duration: 20)
      put :update, id: @meeting.id, :meeting => attr
      @meeting.reload
      expect(@meeting.duration).to eq(20)
      expect(response).to redirect_to(:root)
    end
  end
  describe "POST send_alert" do
=begin
    it "should redirect to phone input if no user" do
      @request.cookies['ucd'] = ""
      post :send_alert
      expect(response).to redirect_to("/users")
    end
    it "should redirect to out of credits page if no credits" do
      u = User.find_by_code(@request.cookies['ucd'])
      u.credits = 0
      u.save
      post :send_alert
      expect(response).to redirect_to("/credits")
    end
    it "should reduce the number of credits" do
      @meeting = Meeting.create(nickname: "Cookie breaker", phone_number: "0401231234", duration: 1300)
      @meeting.create_hashkey
      @request.cookies['curr_me'] = @meeting.hashkey
      @meeting.save
      expect {post :send_alert}.to change {User.find_by_code(@request.cookies['ucd']).credits}.by(-1)
    end
=end
    it "should remove incorrect cookie" do
      @meeting = Meeting.create(nickname: "Cookie breaker", phone_number: "0401231234", duration: 1300)
      @request.cookies['curr_me'] = "dog treat"
      post :send_alert
      expect(@response.cookies['curr_me']).to equal(nil)
    end
    it "should redirect to meet creation when the user has an incorrect cookie" do
      @meeting = Meeting.create(nickname: "Cookie breaker", phone_number: "0401231234", duration: 1300)
      @request.cookies['curr_me'] = "dog treat"
      post :send_alert
      expect(response).to redirect_to(:root)
    end
    it "should redirect to confirmation if correct cookie" do
      @meeting = Meeting.create(nickname: "Cookie breaker", phone_number: "0401231234", duration: 1300)
      @meeting.create_hashkey
      @request.cookies['curr_me'] = @meeting.hashkey
      @meeting.save
      post :send_alert
      expect(response).to redirect_to(:meetings_alert_confirm)
    end
  end
  describe "POST meeting_ok" do
    it "should remove cookie" do
      @meeting = Meeting.create(nickname: "Cookie breaker", phone_number: "0401231234", duration: 20)
      @meeting.create_hashkey
      @request.cookies['curr_me'] = @meeting.hashkey
      @meeting.save
      post :meeting_ok
      expect(@response.cookies['curr_me']).to equal(nil)
    end
    it "should delete the meeting from database" do
      @meeting = Meeting.create(nickname: "Testuser", phone_number: "0401231234", duration: 10)
      @meeting.create_hashkey
      @request.cookies['curr_me'] = @meeting.hashkey
      @meeting.save
      post :meeting_ok
      expect(Meeting.count).to eq(0)
    end
    it "should delete the associated delayed_job" do
      #To properly create a job the meeting has to be created via a post to create. Best not ask why.
      meeting_params = {:nickname => "Pekka", :phone_number => "0401231234", :duration => 30}
      post :create, :meeting => meeting_params
      @meeting = Meeting.find_by_nickname("Pekka")
      expect(Delayed::Job.all.length).to eq(1)
      post :meeting_ok
      expect(Delayed::Job.all.length).to eq(0)
    end
    it "should redirect to root" do
      @meeting = Meeting.create(nickname: "Test", phone_number: "testi@testi.test", duration: 10)

      @meeting.create_hashkey
      @request.cookies['curr_me'] = @meeting.hashkey
      @meeting.save
      post :meeting_ok
      expect(response).to redirect_to(:root)
    end
=begin
    it "should refund notification credits if not used" do
      #To properly create a job the meeting has to be created via a post to create. Best not ask why.
      meeting_params = {:nickname => "Pekka", :phone_number => "0401231234", :duration => 30}
      post :create, :meeting => meeting_params
      @meeting = Meeting.find_by_nickname("Pekka")
      expect {post :meeting_ok}.to change{User.find_by_code(@request.cookies['ucd']).credits}.by(1)
    end
=end
  end
  describe "POST add_time" do
    it "should increase meeting's duration" do
      @meeting = Meeting.create(nickname: "Pekka", phone_number: "9991231234", duration: 10)
      @meeting.create_hashkey
      @request.cookies['curr_me'] = @meeting.hashkey
      @meeting.save
      @meeting.delay(run_at: @meeting.time_to_live.minutes.from_now).send_notification

      expect(@meeting.duration).to eq(10)
      post :add_time
      updated_meeting = Meeting.find_by_hashkey(@meeting.hashkey)
      expect(updated_meeting.duration).to eq(20)
    end
    it "should increase job's run_at time" do
      @meeting = Meeting.create(nickname: "Pekka", phone_number: "9991231234", duration: 10)
      @meeting.create_hashkey
      @request.cookies['curr_me'] = @meeting.hashkey
      @meeting.save
      @meeting.delay(run_at: @meeting.time_to_live.minutes.from_now).send_notification
      job = @meeting.find_job
      start_time = job.run_at
      post :add_time
      job = @meeting.find_job
      expect(job.run_at).to eq(start_time+10.minutes)
    end
  end
  describe "GET meeting_exists" do
    render_views
    it "should find an existing meeting" do
      @meeting = Meeting.create(nickname: "Pekka", phone_number: "9991231234", duration: 10)
      get :exists, :id => @meeting.id
      expect(response.body).to have_content("true")
    end
    it "should not find a meeting that doesn't exist" do
      get :exists, :id => 123493
      expect(response.body).to have_content("false")
    end
  end

  describe "DELETE :id" do
    render_views
    before :each do
      @request.env['HTTP_REFERER'] = "/admin"
    end
    it "should delete existing meeting if authenticated" do
      u = Admin.create(username: "admin", password: "admin", password_confirmation: "admin")
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("admin","admin")
      @meeting = Meeting.new
      @meeting.save(:validate => false)
      delete :destroy, id: @meeting.id
      expect(Meeting.count).to eq(0)
      expect(response.status).to eq(302)
    end
    it "should not delete existing meeting if not authenticated" do
      u = Admin.create(username: "admin", password: "admin", password_confirmation: "admin")
      @meeting = Meeting.new
      @meeting.save(:validate => false)
      delete :destroy, id: @meeting.id
      expect(Meeting.count).to eq(1)
      expect(response.status).to eq(401)
    end
    it "should not delete existing meeting if invalid credentials" do
      u = Admin.create(username: "admin", password: "admin", password_confirmation: "admin")
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("wrong","credentials  ")
      @meeting = Meeting.new
      @meeting.save(:validate => false)
      delete :destroy, id: @meeting.id
      expect(Meeting.count).to eq(1)
      expect(response.status).to eq(401)
    end
    it "should not delete meeting that does not exist" do
      u = Admin.create(username: "admin", password: "admin", password_confirmation: "admin")
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("admin","admin")
      @meeting = Meeting.new
      @meeting.save(:validate => false)
      delete :destroy, id: 12312
      expect(Meeting.count).to eq(1)
      expect(response.status).to eq(302)
    end

  end
end
