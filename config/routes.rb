OopsData::Application.routes.draw do
  get "home/index"
	match 'home' => 'home#index', :as => :home

	resources :registrations
	match 'input_activate_email' => 'registrations#input_activate_email', :as => :input_activate_email
	match 'send_activate_email' => 'registrations#send_activate_email', :as => :send_activate_email, :via => [:post]
	match 'activate' => 'registrations#activate', :as => :activate
	match 'check_email' => 'registrations#email_illegal', :as => :check_email, :via => [:get, :post]

	resources :sessions
	match 'logout' => 'sessions#destroy', :as => :logout
	match 'login' => 'sessions#create', :as => :login
	match 'forget_password' => 'sessions#forget_password', :as => :forget_password
	match 'send_password_email' => 'sessions#send_password_email', :as => :send_password_email, :via => [:post]
	match 'input_new_password' => 'sessions#input_new_password', :as => :input_new_password
	match 'new_password' => 'sessions#new_password', :as => :new_password, :via => [:post]

	resources :users
	match 'update_information' => 'users#update_information', :as => :update_information, :via => [:post]
	match 'reset_password' => 'users#reset_password', :as => :reset_password, :via => [:post]

	resources :groups

	resources :surveys do
		collection do
			post 'save_meta_data'
		end
		member do
			get 'clone'
		end
		resources :pages
		resources :questions do 
		end
	end
	match 'surveys/:survey_id/pages/:page_index_1/:page_index_2/move' => 'pages#move'
	match 'surveys/:survey_id/pages/:page_index_1/:page_index_2/combine' => 'pages#combine'
	match 'surveys/:survey_id/pages/:page_index_1/:page_index_2/clone' => 'pages#clone'
	match 'surveys/:survey_id/pages/:page_index/questions/:question_id_1/:question_id_2/move' => 'questions#move'
	match 'surveys/:survey_id/pages/:page_index/questions/:question_id_1/:question_id_2/clone' => 'questions#clone'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
