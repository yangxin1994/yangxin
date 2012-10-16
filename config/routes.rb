require 'resque/server'
OopsData::Application.routes.draw do

	mount Resque::Server.new, :at => "/resque"

	resources :faqs, :public_notices, :feedbacks, :advertisements
	resources :data_generators do
		collection do
			get 'generate'
		end
	end

	namespace :admin do
		resources :users do 
			collection do 
				get 'blacks'
				get 'whites'
			end

			member do 
				get 'system_pwd'
				get 'white'
				get 'black'
			end
		end

		resources :faqs do 
			collection do 
				get 'count'
				get 'list_by_type_count'
				get 'list_by_type_and_value_count'
			end
		end
		resources :public_notices do 
			collection do 
				get 'count'
				get 'list_by_type_count'
				get 'list_by_type_and_value_count'
			end
		end
		resources :advertisements do 
			collection do 
				get 'count'
				get 'list_by_title_count'
				get 'activated_count'
				get 'unactivate_count'
			end
		end
		resources :system_users do 
			collection do 
				post 'lock'
				post 'unlock'
			end
		end
		resources :feedbacks do
			collection do 
				get 'count'
				get 'list_by_type_and_value_count'
				get 'list_by_type_and_answer_count'
				get 'list_by_type_count'
			end
			member do 
				post 'reply'
			end
		end

		resources :quality_control_questions do
			member do
				put 'update_answer'
			end
		end

		resources :template_questions do
		end

	# The priority is based upon order of creation:
	# first created -> highest priority.

	# Sample of regular route:
	#	 match 'products/:id' => 'catalog#view'
	# Keep in mind you can assign values other than :controller and :action

	end

	namespace :survey_auditor do
		resources :surveys do
			member do
				get 'reject'
				get 'publish'
				get 'close'
				get 'pause'
			end
		end
	end

	get "home/index"
	match 'home' => 'home#index', :as => :home
	post "home/get_tp_info"
	post "home/get_more_info"


	resources :registrations do
		collection do
			post :create_new_visitor_user
		end
	end
	match 'input_activate_email' => 'registrations#input_activate_email', :as => :input_activate_email
	match 'send_activate_email' => 'registrations#send_activate_email', :as => :send_activate_email, :via => [:post]
	match 'activate' => 'registrations#activate', :as => :activate
	match 'check_email' => 'registrations#email_illegal', :as => :check_email, :via => [:get, :post]

	resources :sessions do
		collection do
			post :update_user_info, :init_basic_info, :init_user_attr_survey, :send_password_email
			get :obtain_user_attr_survey, :skip_init_step
			post :new_password, :reset_password
			get :forget_password, :input_new_password
			post :login_with_auth_key
		end
	end
	match 'logout' => 'sessions#destroy', :as => :logout
	match 'login' => 'sessions#create', :as => :login
	match 'renren_connect' => 'sessions#renren_connect', :as => :renren_connect
	match 'sina_connect' => 'sessions#sina_connect', :as => :sina_connect
	match 'qq_connect' => 'sessions#qq_connect', :as => :qq_connect
	match 'google_connect' => 'sessions#google_connect', :as => :google_connect
	match 'qihu_connect' => 'sessions#qihu_connect', :as => :qihu_connect

	resources :users do 
		collection do 
			get :get_basic_info
		end
	end
	match 'update_information' => 'users#update_information', :as => :update_information, :via => [:post]
	match 'reset_password' => 'users#reset_password', :as => :reset_password, :via => [:post]

	resources :groups

	resources :surveys do
		collection do
			post 'list'
		end
		member do
			put 'save_meta_data'
			get 'clone'
			get 'recover'
			get 'clear'
			put 'update_tags'
			put 'add_tag'
			put 'remove_tag'
			put 'submit'
			put 'close'
			get 'reject'
			get 'publish'
			get 'pause'
			put 'update_style_setting'
			get 'show_style_setting'
			put 'update_access_control_setting'
			get 'show_access_control_setting'
			get 'set_random_quality_control_questions'
			get 'get_random_quality_control_questions'
			get 'show_quality_control'
			get 'check_progress'
			get 'estimate_answer_time'
			post 'update_deadline'
			post 'update_star'
			post 'refresh_quota_stats'
		end
		resources :pages do
			member do
				put 'move'
				put 'clone'
				put 'split'
				put 'combine'
			end
		end
		resources :questions do
			collection do
				post 'insert_template_question'
				post 'insert_quality_control_question'
			end
			member do
				put 'convert_template_question_to_normal_question'
				put 'move'
				put 'clone'
			end
		end
		resources :logic_controls
		resources :quotas do
			collection do
				post :set_exclusive
				get :get_exclusive
			end
		end

		resources :filters do
		end

		resources :analyze_results do
			collection do
				get :check_progress
			end
		end

		resources :report_mockups do
		end
	end

	resources :materials do
		member do
			get 'clear'
		end
	end

	resources :quality_control_questions do
		member do
			put 'update_answer'
		end
	end

	resources :template_questions do
	end

	resources :answers do
		collection do
			get 'preview_load_question'
			get 'load_question'
			post 'clear'
			post 'submit_answer'
			post 'finish'
		end
	end

	resources :messages do
		collection do 
			get :unread_count
		end
	end

	resources :lotteries do
		member do
			get :draw
		end
	end
	resources :presents do
		collection do
			get :index, :virtualgoods, :cash, :realgoods, :stockout
			get 'edit'
		end
	end
	resources :orders do
		collection do
			get :for_cash, :for_realgoods, :for_virtualgoods, :for_lottery
		end
	end
	resources :points, :only => 'index'

	resources :tools do
		collection do
			get :find_provinces
			get :find_cities_by_province
			get :find_towns_by_city
			post :send_email
		end
	end

	namespace :admin do
		resources :points do
			new do
				post :operate
			end
		end
		resources :presents do
			collection do
				get 'expired'
				delete 'delete'
			end
		end
		resources :orders do
			collection do
				get :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed
			end
		end
		resources :lotteries do

		end
		resources :lottery_codes do
			
		end

		match 'messages/count' => 'messages#count'
		resources :messages
	end

	# The priority is based upon order of creation:
	# first created -> highest priority.

	# Sample of regular route:
	#	 match 'products/:id' => 'catalog#view'
	# Keep in mind you can assign values other than :controller and :action

	# Sample of named route:
	#	 match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
	# This route can be invoked with purchase_url(:id => product.id)

	# Sample resource route (maps HTTP verbs to controller actions automatically):
	#	 resources :products

	# Sample resource route with options:
	#	 resources :products do
	#		 member do
	#			 get 'short'
	#			 post 'toggle'
	#		 end
	#
	#		 collection do
	#			 get 'sold'
	#		 end
	#	 end

	# Sample resource route with sub-resources:
	#	 resources :products do
	#		 resources :comments, :sales
	#		 resource :seller
	#	 end

	# Sample resource route with more complex sub-resources
	#	 resources :products do
	#		 resources :comments
	#		 resources :sales do
	#			 get 'recent', :on => :collection
	#		 end
	#	 end

	# Sample resource route within a namespace:
	#	 namespace :admin do
	#		 # Directs /admin/products/* to Admin::ProductsController
	#		 # (app/controllers/admin/products_controller.rb)
	#		 resources :products
	#	 end

	# You can have the root of your site routed with "root"
	# just remember to delete public/index.html.
	root :to => 'welcome#index'

	# See how all your routes lay out with "rake routes"

	# This is a legacy wild controller route that's not recommended for RESTful applications.
	# Note: This route will make all actions in every controller accessible via GET requests.
	# match ':controller(/:action(/:id(.:format)))'
end
