require 'sidekiq/web'
OopsData::Application.routes.draw do

  match '*path' => 'welcome#index'
  # get '/:unique_key' => 'utility/short_urls#show', :constraints => { :unique_key => /~.+/ }
  match '/:unique_key' => 'mongoid_shortener/shortened_urls#translate', :via => :get, :constraints => { :unique_key => /~.+/ }

  # accounts
  scope :module => 'account' do
    resource :signup, :only => [:show, :create]
    resource :activate, :only => [:new, :create, :show] do
      member do
        get :done
      end
    end
    resource :password, :only => [:update] do
      member do
        get :find
        post :send_reset_email
        get :reset
      end
    end
    resource :signin, :only => [:show, :create]
    resources :connects, :only => [:show]
    resource :signout, :only => [:show]
    resource :profile, :only => [:show, :update] do
      member do
        put :update_password
      end
    end
    resources :messages, :only => [:index]
  end

  resources :jobs, :only => [:show] do
    member do
      get :data_list, :stats, :analysis_result, :file_uri
    end
  end

  # surveys, pages and questions
  scope :module => "quill" do
    # home
    resource :index, :only => [:show]
    resource :doc, :only => [] do
      member do
        get :design, :share, :result, :export
      end
    end
    resource :customer, :only => [:show]
    resource :aboutus, :only => [:show]
    # survey
    match "questionaires/new" => "questionaires#new", :as => :new_questionaire, :via => :get
    match "questionaires/:questionaire_id" => "questionaires#show", :as => :questionaire, :via => :get  # ugly but make ensure_survey in quill_controller work
    match "questionaires/:questionaire_id" => "questionaires#destroy", :as => :questionaire, :via => :delete
    resources :questionaires, :only => [:index, :new] do
      member do
        put :recover
        get :stars
        get :remove
        put :update_star
        post :clone
        put :publish
        put :deadline
        put :close
      end
      resources :pages, :only => [:create, :show] do
        member do
          put :split
          put :combine
        end
      end
      resources :questions, :only => [:create, :show, :update, :destroy] do
        member do
          put :move
          get :analyse
        end
      end

      resource :authority, :only => [:show, :update]
      resource :property, :only => [:show, :update] do
        member do
          get :more
          put :update_more
        end
      end
      resource :quality, :only => [:show, :update]
      resource :customization, :only => [:show, :update]
      resources :logics, :only => [:index, :show, :destroy, :update, :create]

      resource :share, :only => [:show]
      resources :quotas, :only => [:destroy, :update, :create] do
        collection do
          post :refresh
        end
      end

      resources :filters, :only => [:index, :show, :destroy, :update, :create]
      resources :report_mockups, :only => [:index, :show, :create, :update, :destroy] do
        member do
          get :report
        end
      end
      resource :result, :only => [:show] do
        member do
          get :spss, :excel, :report, :csv_header
          post :import_data
        end
      end

      resource :preview, :only => [:show]
    end #end of resources questionaire
    resources :functions, :only => [] do
      collection do
        get :design
      end
    end
  end

  # sample
  scope :module => "sample" do
    match 'sign_up' => "accounts#sign_up",:via => :get
    match 'sign_in' => "accounts#sign_in",:via => :get
    match 'sign_out' => "accounts#sign_out",:via => :get

    resource :account, :only => [] do
      get  :sign_in, :as => :sign_in
      get  :after_sign_in, :as => :after_sign_in
      get  :sign_up, :as => :sign_up
      post :login,   :as => :login 
      get  :sign_out,:as => :sign_out
      post :create_sample,:as => :create_sample
      get  :check_email_mobile,:as => :check_email_mobile
      get  :active_notice,:as => :active_notice
      get  :email_activate,:as => :email_activate
      post :mobile_activate,:as => :mobile_activate
      get  :re_mail,:as => :re_mail
      post  :get_basic_info_by_auth_key, :as => :get_basic_info_by_auth_key
      get :forget_password, :as => :forget_password
      get :send_forget_pass_code,:as => :send_forget_pass_code
      get :make_forget_pass_activate, :as => :make_forget_pass_activate
      get :generate_new_password,:as => :generate_new_password
      get :get_account,:as => :get_account,:as => :get_account
    end

    resource :home, :only => [:show] 

    resources :surveys, :only => [:index] do 
      collection do
        get  :get_special_status_surveys
        post :get_reward_type_count
        post :make_rss_activate
        get  :active_rss_able
        get  :make_rss_mobile_activate
        get  :re_rss_mail
        get  :cancel_subscribe
      end
      member do
        get :result
      end
    end

    resources :orders do 
      collection do 
        post :create_lottery_order, :as => :create_lottery_order
      end
    end

    resources :lotteries do
      member do 
        get :draw
      end 
    end

    resources :users,:except => [:show] do
          collection do
            # 
            get 'get_mobile_area'
            # surveys
            get 'join_surveys', 'spread_surveys'
            get 'surveys' => 'users#join_surveys'
            match '/spread_counter/:id' => "users#spread_counter", :via => :get
            match '/survey_detail/:id' => "users#survey_detail", :via => :get
            # points
            get 'points'
            # orders
            get 'orders'
            match '/order_detail/:id' => "users#order_detail", :via => :get
            # setting
            get 'setting' => 'users#basic_info'
            put 'setting/update_basic_info' => "users#update_basic_info"
            get 'setting/avatar' => 'users#avatar'
            post 'setting/upload_avatar' => 'users#update_avatar'
            get 'setting/bindings' => 'users#bindings'
            match 'setting/unbind/:website' => 'users#unbind', :via => :put
            put 'setting/share' => 'users#bind_share'
            put 'setting/subscribe' => 'users#bind_subscribe'
            put 'setting/change_mobile' => 'users#change_mobile' 
            put 'setting/check_mobile_verify_code' => 'users#check_mobile_verify_code'
            put 'setting/change_email' => 'users#change_email'
            get 'setting/change_email_verify_key' => 'users#change_email_verify_key'
            get 'setting/address' => 'users#address'
            put 'setting/address' => 'users#update_logistic_address'
            get 'setting/password' => 'users#password'
            put 'setting/password' => 'users#update_password'
            # notifications
            get 'notifications'
            match 'notifications/:id' => 'users#destroy_notification', :via => :delete
            delete 'notifications' => 'users#remove_notifications'
          end 
        end

    resources :gifts, :only => [:index, :show] do
      collection do 
        get :get_special_type_data
      end
    end
    resources :prizes, :only => [:show] do
      collection do
        post :find_by_ids 
      end            
    end
    resources :users,:only => [:index,:show]
    resource :help, :only =>[] do
      member do
        get :survey, :lottery, :gift, :reward, :aboutus
      end
    end
    
    resources :public_notices, :only => [:index,:show]      
  end

  # utility
  namespace :utility do
    resource :address, :only => [] do
      member do
        get :provinces
        get :cities
        get :towns
      end
    end
    resources :materials do
      collection do
        get :video_upload_path
        post :create_image
      end
      member do
        get :preview
      end
    end
    resources :short_urls, :only => [:show]
    resources :ofcards do
      collection do
        get :confirm
        post :confirm
      end
    end
  end

  namespace :answer_auditor, :module => 'admin' do
    get ''=> 'review_answers#index'
    resources 'review_answers', :as => 'answer_auditor' do
      member do
        get '/answers/:answer_id' => "review_answers#show_answer"
        put '/answers/:answer_id/review' => "review_answers#review"
      end
    end
  end

  namespace :survey_auditor, :module => 'admin' do
    get ''=> 'reviews#index'
    resources 'reviews', :as=>'survey_auditor' do
      member do
        put 'publish', 'close', 'pause', 'reject'
      end
    end
  end

  # admin
  namespace :admin do
    get "" => "surveys#index"
    get "/:id/get_email" => "admin#get_email"
    resources :reviews do
      member do
        put 'publish', 'close', 'pause', 'reject'
      end
    end
    resources :publishes do
      member do
        put 'allocate', 'add_reward', 'set_community', 'set_spread', 'cancel_community', 'set_answer_need_review', 'set_promotable'
      end
      resources :interviewer_tasks do
      end
    end
    resources :costs, :only => [:index, :show]
    resources :review_answers do
      member do
        get '/answers/:answer_id' => "review_answers#show_answer"
        put '/answers/:answer_id/review' => "review_answers#review"
      end
    end

    resources :template_questions do
      collection do
        get 'clear_cart'
        post  'add_to_cart', 'del_cart'
      end
      member do
        get 'get_text'
      end
    end

    resources :quality_questions do
      collection do
        get 'objective', 'matching'
      end
      member do
        put 'update_answer'
      end
    end
    resources :volunteer_surveys do
      collection do
        post "add_template_question"
        delete 'del_question'
      end
    end
    resources :gifts do
      member do
        put 'stockup', 'outstock'
      end
    end
    resources :prizes
    resources :surveys, :as => :s do
      member do
        get :reward_schemes, :promote, :more_info, :bind_question
        put :update_promote, :set_info, :bind_question, :star
        post :update_promote
        delete :destroy_attributes, :bind_question
      end
      collection do

      end
    end



    resources :reward_schemes

    resources :samples do
      member do
        get :redeem_log, :point_log, :lottery_log, :answer_log, :spread_log, :edit_attributes
        delete :destroy_attributes
        put :set_sample_role, :operate_point, :block
      end
      collection do
        post :add_attributes, :send_message
        get :attributes, :new_attributes, :status, :get_sample_count, :get_active_sample_count
      end
    end

    resources :answers do
      member do
        get :review
      end
    end

    resources :rewards do
      collection do
        post :operate_point
      end
    end
    resources :orders, :only => [:index, :show, :update] do
      collection do
        get :to_excel
      end
      member do
        put :handle, :bulk_handle, :finish, :bulk_finish, :update_express_info, :update_remark
      end
    end
    resources :lotteries do
      member do
        get :auto_draw, :reward_records, :assign_prize, :lottery_codes , :ctrl
        put :assign_prize, :add_ctrl_rule, :status , :assign_prize_to, :revive
      end
      collection do
        get :deleted
      end
    end
    resources :materials
    resources :users do
      collection do
        get 'blacks', 'whites',
          'deleted', 'normal', 'search'
      end
      member do
        put 'recover', 'add_point', 'set_role', 'set_color', 'reset_password', 'set_lock'
        get 'get_email', 'orders', 'rewards', 'lottery_record', 'point_logs','introduced_users'
      end
    end
    resources :newsletters do
      member do
        post   :deliver
        post   :test
        delete :cancel
      end
      collection do
        post   :column
        post   :article
        post   :product_news
      end
    end
    resources :subscribers do
      member do
        put :unsubscribe, :subscribe
      end
    end
    resources :faqs do
    end
    resources :announcements do
    end
    resources :advertisements do
    end
    resources :feedbacks do
      member do
        post 'reply'
      end
    end
    resources :messages do
    end
    resources :sample_attributes, :only => [:index, :create, :update, :destroy]
    get "sample_attributes/bind_question/:id" => "sample_attributes#bind_question"
    put "sample_attributes/bind_question/:id" => "sample_attributes#bind_question"
    delete "sample_attributes/bind_question/:id" => "sample_attributes#bind_question", as: :sample_attribute_bind

    resources :agents
    resources :agent_tasks do
      member do
        put :close, :open
      end
    end
    
    resources :sample_stats, :only => [:index] do
      collection do
      get :get_sample_count
      get :get_active_sample_count
      end
    end
  end

  namespace :agent do
    scope :module => :sessions do
      resources :signin
      resources :signout
      resources :reset_password
    end
    resources :answers do
      member do
        put :review
      end
    end
    resources :tasks do
      member do
        put :close, :open
      end
    end
  end

  # Survey filler
  scope :module => "filler" do
    match "s/:id" => "surveys#show", :as => :show_s, :via => :get
    resources :surveys, :only => [:show] 
    match "p/:id" => "previews#show", :as => :show_p, :via => :get
    resources :previews, :only => [:show]
    match "a/:id" => "answers#show", :as => :show_a, :via => :get
    resources :answers, :only => [:show, :create, :update] do
      member do
        get :load_questions
        post :finish
        post :clear
        delete :destroy_preview
        put :select_reward
        post :start_bind
      end
    end
    resource :bind_sample, :only => [:show]
  end

  # Root: different roots for diffent hosts
  constraints :subdomain => "admin" do
    root :to => 'admin/publishes#index', as: :admin_root
  end
  # constraints :subdomain => "quillme" do
  #   root :to => 'sample/homes#show', as: :quillme_root
  # end
  # constraints :subdomain => "quillmeapi" do
  #   root :to => 'sample/homes#show', as: :quillmeapi_root
  # end
  # constraints :subdomain => "quillmedev" do
  #   root :to => 'sample/homes#show', as: :quillmedev_root
  # end
  # root :to => "sample/homes#show", :constraints => { :domain => "oopsdata.cn" }, as: :oopsdatacn_root
  # root :to => "sample/homes#show", :constraints => { :domain => "wenjuanba.com" }, as: :wenjuanbacom_root
  # root :to => 'quill/indices#show'
  # root :to => "sample/homes#show"
  root :to => "welcome#index"
end
