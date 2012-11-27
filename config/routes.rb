require 'resque/server'
OopsData::Application.routes.draw do

	mount Resque::Server.new, :at => "/resque"

	resources :jobs do
		collection do
			post :email_job
			post :result_job
		end
	end

	resources :faqs, :public_notices, :feedbacks, :advertisements
	resources :data_generators do
		collection do
			get 'generate'
		end
	end

	namespace :super_admin do
		resources :users do
			member do
				put 'set_admin'
			end
		end
	end

	resources :quality_control_questions do
	end
	
	resources :lottery_codes 


	# alias interface
	match '/admin/surveys/new' => 'surveys#new'
	# 
	namespace :admin do
		resources :users do 
			collection do 
				get 'blacks', 'whites', 'deleteds','list_by_role'
			end

			member do
				get 'get_email', 'get_introduced_users'
				put 'set_color', 'set_role', 'set_lock', 'system_pwd', 'recover','add_point'
			end
		end

		resources :surveys do 
			collection do 
				get 'wait_to_community' , 'show_user_attr_survey'
				put 'add_questions'
			end
			member do
				put 'allocate', 'add_reward', 'set_community', 'set_spread'
			end
		end

		resources :faqs do 
			collection do 
				get 'count', 'list_by_type_count', 'list_by_type_and_value_count'
			end
		end
		resources :public_notices do 
			collection do 
				get 'count', 'list_by_type_count', 'list_by_type_and_value_count'
			end
		end
		resources :advertisements do 
			collection do 
				get 'count', 'list_by_title_count', 'activated_count', 'unactivate_count'
			end
		end

		resources :feedbacks do
			collection do 
				get 'count', 'list_by_type_count', 'list_by_type_and_value_count', 
					'list_by_type_and_answer_count'
			end
			member do 
				post 'reply'
			end
		end

		resources :quality_control_questions do
			collection do 
				get 'objective_questions', 'objective_questions_count', 
					'matching_questions', 'matching_questions_count'
			end
			member do
				put 'update_answer'
			end
		end

		resources :template_questions do
			collection	 do 
				get 'count', 'list_by_type', 'list_by_type_count'
			end
			member do 
				get 'get_text'
			end
		end

		resources :points do
			new do
				post :operate
			end
		end
		resources :gifts do
			collection do
				get :virtual, :cash, :entity, :lottery
				get :expired, :index, :virtual, :cash, :entity, :stockout
			end
		end
		resources :prizes do
			collection do
				get :virtual, :cash, :entity, :lottery, :for_lottery
				get :expired, :index, :virtual, :cash, :entity, :stockout
			end
		end
		resources :orders do
			collection do
				get :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed
			end
		end
		
		resources :lotteries do
			collection do
				get :for_publish, :activity, :finished
			end
		end

		resources :reward_logs do
			collection do
				get :for_points, :for_lotteries
			end
		end

		resources :lottery_codes 

		match 'messages/count' => 'messages#count'
		resources :messages

		resources :rewards, :only => [:index] do
			collection do
				post :operate_point, :revoke_operation
				get :for_points, :for_lotteries
			end
		end
	# The priority is based upon order of creation:
	# first created -> highest priority.

	# Sample of regular route:
	#	 match 'products/:id' => 'catalog#view'
	# Keep in mind you can assign values other than :controller and :action

	end

	namespace :answer_auditor do
		resources :surveys do
		end
		resources :answers do
			member do
				put 'review'
			end
		end
	end

	namespace :survey_auditor do
		resources :surveys do
			collection do 
				get 'count'
			end
			member do
				get 'reject'
				get 'publish'
				get 'close'
				get 'pause'
			end
		end
	end

	namespace :answer_auditor do 
		resources :answers do 
			collection do 
				get 'count'
			end
		end
	end

	namespace 'entry_clerk' do
		resources :answers do
			member do
				get 'csv_header'
				post 'import_answer'
			end
		end
	end

	get "home/index"
	match 'home' => 'home#index', :as => :home
	post "home/get_tp_info"
	post "home/get_more_info"


	resources :registrations do
		collection do
			post :send_activate_email
			post :activate
		end
	end

	resources :sessions do
		collection do
			post :update_user_info, :init_basic_info, :init_user_attr_survey, :send_password_email
			get :obtain_user_attr_survey, :skip_init_step
			post :new_password, :reset_password
			post :login_with_auth_key
			post :login_with_code
		end
	end
	match 'logout' => 'sessions#destroy', :as => :logout
	match 'login' => 'sessions#create', :as => :login

	resources :users do 
		collection do 
			get :get_level_information
			get :get_basic_info
			get :get_introduced_users
			get :point
			get :lottery_codes
		end
		member do 
			get 'get_email'
		end
	end
	match 'update_information' => 'users#update_information', :as => :update_information, :via => [:post]
	match 'reset_password' => 'users#reset_password', :as => :reset_password, :via => [:post]

	resources :groups

	resources :surveys do
		collection do
			get 'list_surveys_in_community'
			get 'list_answered_surveys'
			get 'list_spreaded_surveys'
			get 'search_title'
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
			put 'update_quality_control'
			get 'show_quality_control'

			get 'update_deadline'

			get 'show_quality_control'
			get 'check_progress'
			get 'estimate_answer_time'
			put 'update_deadline'
			post 'update_star'
			get 'reward_info'
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
				delete 'delete_quality_control_question'
			end
		end
		resources :logic_controls do
			collection do
				get :list_with_question_objects
			end
		end
		resources :quotas do
			collection do
				post :set_exclusive
				get :get_exclusive
				post :refresh
			end
		end

		resources :filters do
		end

		resources :results do
			collection do
				get :check_progress
				get :job_progress
				get :data_list
				get :analysis
				get :to_spss
				get :to_excel
				get :report
				put :finish
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
			get 'get_my_answer'
		end
		member do
			get 'load_question'
			post 'clear'
			post 'submit_answer'
			post 'finish'
			get 'estimate_remain_answer_time'
			delete 'destroy_preview'
		end
	end

	resources :messages do
		collection do 
			get :unread_count
		end
	end

	resources :lotteries do
		collection do
			get :own
		end
		member do
			get :draw
		end
	end
	resources :gifts do
		collection do
			get :virtual, :cash, :entity, :lottery

		end
		member do
			put :exchange
		end
	end
	resources :orders do
		collection do
			get :for_cash, :for_entity, :for_virtual, :for_lottery
			get :need_verify, :verified, :verify_failed, :delivering, :delivering, :delivered, :deliver_failed
		end
	end

	resources :reward_logs do
		collection do
			get :for_points, :for_lotteries

		end
	end

	resources :tools do
		collection do
			get :find_provinces
			get :find_cities_by_province
			get :find_towns_by_city
			post :send_email
		end

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
