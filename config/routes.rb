require 'sidekiq/web'
OopsData::Application.routes.draw do
	mount Sidekiq::Web, at: "/sidekiq"

	resources :faqs, :public_notices, :feedbacks, :advertisements
	resources :ofcards do
		collection do
			post :confirm
		end
	end

	namespace :agent do
		resources :sessions do
			collection do
				get :login_with_auth_key
				put :reset_password
			end
		end

		resources :agent_tasks do
			member do
				put :close
			end
		end

		resources :answers do
			member do
				put :review
			end
		end
	end

	resources :quality_control_questions do
	end

	resources :lottery_codes

	resources :browser_extensions do
	end

	resources :browsers do
		member do
			put :update_history
			get :get_recommended_surveys
			get :get_survey_info
		end
	end


	# alias interface
	match '/admin/surveys/new' => 'surveys#new'
	#
	match '/subscribe' , :to => 'subscribers#create', :as => '/subscribe'
	match '/unsubscribe' , :to =>'subscribers#destroy', :as => '/subscribe'
	namespace :admin do
		resources :answer_auditors, :only => [:index]
		resources :agent_tasks do
			member do
				put :close, :open
			end
		end

		resources :agents do
		end

		resources :materials do
		end

		resources :questions do
			member do
				put :remove_sample_attribute
			end
		end

		resources :sample_attributes do
			member do
				put :bind_question
			end
		end

		resources :samples do
			member do
				get :point_log, :redeem_log, :lottery_log
				post :block
				put :set_sample_role
			end
			collection do
				post :send_message
				get :count, :active_count, :attributes_completion, :attributes_statistics
			end
		end

		resources :browsers do
			collection do
				get :role
				get :tasks
			end
		end

		resources :users do
			collection do
				get 'blacks', 'whites', 'deleteds','list_by_role'
			end

			member do
				get 'get_email', 'get_introduced_users', 'lottery_codes', 'orders', 'point_logs'
				put 'set_color', 'set_role', 'set_lock', 'system_pwd', 'recover','add_point'
			end
		end
		resources :newsletters do
			collection do
				get :editing, :delivering, :delivered, :canceled
			end
			member do
				post :deliver
				post :test
				delete :cancel
			end
		end
		resources :subscribers do
			collection do
				get :subscribed, :unsubscribed, :search
			end
			member do
				put :unsubscribe, :subscribe
			end
		end
		resources :surveys do
			collection do
				put 'add_template_question'
			end
			member do
				put 'add_reward', 'set_community', 'set_promotable', 'set_answer_need_review', 'background_survey',
						'quillme_promote', 'email_promote', 'sms_promote', 'broswer_extension_promote', "weibo_promote"
				get 'get_sent_email_number', 'promote'
				put :quillme_hot, :allocate_answer_auditors, :set_result_visible, :set_spread
				put :add_sample_attribute_for_promote, :remove_sample_attribute_for_promote
				get :get_spread, :get_result_visible
			end
			resources :reward_schemes, :except => [:new, :edit, :destroy]
		end

		resources :interviewer_tasks do
		end

		resources :faqs do
		end
		resources :public_notices , :except => [:new, :edit]
		resources :advertisements do
			collection do
				get 'count', 'list_by_title_count', 'activated_count', 'unactivate_count'
			end
		end

		resources :feedbacks do
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
			collection do
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
				put :bulk_handle, :bulk_finish 
			end
			member do
				put :handle, :finish, :update_express_info, :update_remark
			end
		end
		
		resources :lotteries do
			collection do
				get :for_publish, :activity, :finished, :deleted, :quillme
			end
			member do
				get :auto_draw, :prize_records, :lottery_codes, :ctrl
				put :assign_prize, :add_ctrl_rule, :revive
			end
		end

		resources :reward_logs do
			collection do
				get :for_points, :for_lotteries
			end
		end

		resources :lottery_codes

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
		resources :answers , :only => [:index, :show, :destroy] do
			member do
				put 'review'
			end
			collection do
				put "review_agent_answers"
			end
		end
	end

	namespace 'interviewer' do
		resources :surveys do
		end
		resources :interviewer_tasks do
			resources :answers do
				collection do
					post 'submit'
				end
			end
		end
		resources :materials do
		end
	end

	get "home/index"
	match 'home' => 'home#index', :as => :home
	post "home/get_tp_info"
	post "home/get_more_info"


	resources :registrations, :only => [:create] do
		collection do
			post :send_activate_key
			post :email_activate, :mobile_activate
			get :registered_user_exist
		end
	end

	resources :sessions, :only => [:create] do
		collection do
			post :login_with_auth_key, :third_party_sign_in
			delete :destroy
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
			put 'publish'
			put 'close'
			put 'update_style_setting'
			get 'show_style_setting'
			put 'update_access_control_setting'
			get 'show_access_control_setting'
			put 'update_quality_control'
			get 'show_quality_control'

			get 'update_deadline'

			get 'show_quality_control'
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
		resources :report_mockups do
		end
	end
	resources :results do
		collection do
			get :check_progress
			get :job_progress
			get :analysis
			get :to_spss
			get :to_excel
			get :report
			put :finish
			get :get_data_list
			get :get_stats
			get :get_analysis_result
			get :get_file_uri
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
			post :exchange
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
		member do
			put :cancel
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
			get :find_address_text_by_code
			post :send_email
		end
	end
	
	namespace :sample do
		resources :reward_schemes do
		end
		resources :accounts do
			collection do
				get :get_basic_info
				get :get_basic_attributes
				put :set_basic_attributes
				get :get_receiver_info
				put :set_receiver_info
				put :reset_password
				get :messages
				delete :destroy_message
				delete :destroy_all_messages
				get :get_bind_info
				put :unbind
				put :set_share
				put :set_subscribe
				put :send_change_email
				put :send_change_sms
				put :change_email
				put :change_mobile
			end	
		end	
		resources :surveys do
			collection do
				get :get_hot_spot_survey,:as => :get_hot_spot_survey
				get :get_recommends,:as => :get_recommends
				get :list_answered_surveys,:as => :list_answered_surveys
				get :list_spreaded_surveys,:as => :list_spreaded_surveys
				get :get_reward_type_count,:as => :get_reward_type_count
			end
		end		
		resources :public_notices do
			collection do
				get :get_newest,:as => :get_newest
			end
		end
		resources :gifts do
			collection do
				get :hotest,:as => :hotest
			end
		end  		
		resources :prizes do
			collection do
				post :get_prizes,:as => :get_prizes
			end
		end      
		resources :users do
			collection do
				get :get_top_ranks,:as => :get_top_ranks
				get :get_my_third_party_user,:as => :get_my_third_party_user
				get :mobile_banding,:as => :mobile_banding
				get :email_banding,:as => :email_banding
				get :info_precent_complete,:as => :info_precent_complete
				post :make_rss_activate,:as => :make_rss_activate
				get :make_subscribe_active,:as => :make_subscribe_active
				get :make_rss_mobile_activate,:as => :make_rss_mobile_activate
				put :send_forget_pass_code,:as => :send_forget_pass_code
				put :make_forget_pass_activate,:as => :make_forget_pass_activate
				put :generate_new_password,:as => :generate_new_password
				get :get_account_by_activate_key,:as => :get_account_by_activate_key
			end
		end
		resources :logs do
			collection do
				get :fresh_news,:as => :fresh_news
				get :get_disciplinal_news,:as => :get_disciplinal_news
				get :get_newst_exchange_logs,:as => :get_newst_exchange_logs
				get :get_point_change_log
				get :find_lottery_logs
			end
		end
		resources :answers do 
			collection do 
				get :get_today_answers_count,:as => :get_today_answers_count
				get :get_today_spread_count, :as => :get_today_spread_count
				get :get_answer_id_by_auth_key
				# get :get_my_answer
				get :list_spreaded_answers
				get :spreaded_answer_number
			end
			member do
				get :load_question
				post :clear
				post :submit_answer
				post :finish
				get :estimate_remain_answer_time
				delete :destroy_preview
				post :change_sample_account
				delete :logout
				put :select_reward
				post :bind_sample
				put :draw_lottery
				post :create_lottery_order
				get :find_lottery_answers
				get :get_lottery_counts
			end
		end	
		resources :orders do
			collection do
				post :create_gift_order, :as => :create_gift_order 
			end
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
