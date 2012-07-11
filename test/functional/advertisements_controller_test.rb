require 'test_helper'

class AdvertisementsControllerTest < ActionController::TestCase
  
  test "01 should not get index with a normal user" do 
  	clear(User, Advertisement)
  	
  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 0
		user.save
		
		sign_in(user.email, Encryption.decrypt_password(user.password))
		get 'index', :format => :json
		retval = @response.body.to_i
		assert_equal retval, ErrorEnum::REQUIRE_ADMIN
		sign_out
		
		clear(User, Advertisement)
  end
  
  test "02 should get index with a admin user" do 
  	clear(User, Advertisement)
  	
  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		sign_in(user.email, Encryption.decrypt_password(user.password))
		get 'index', :format => :json
		assert_equal JSON.parse(@response.body), []
		sign_out
		
		clear(User, Advertisement)
  end
  
  test "03 should post create with a admin user" do 
  	clear(User, Advertisement)
  	
  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :advertisement => {title: "title1", linked: "www.baidu.com"} ,:format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["title"], "title1"
		advertisement = Advertisement.where(title: "title1").first
		assert_equal advertisement.linked, "www.baidu.com"
		assert_equal advertisement.user, user
		sign_out
		
		clear(User, Advertisement)
  end
  
  test "03 should post update with a admin user" do 
  	clear(User, Advertisement)
  	
  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		#create
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :advertisement => {title: "title1", linked: "www.baidu.com"} ,:format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["title"], "title1"
		advertisement = Advertisement.where(title: "title1").first
		assert_equal advertisement.linked, "www.baidu.com"
		assert_equal advertisement.user, user
		sign_out
		
		#update title/linked/user attributes.
		user = User.new(email: "test2@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'update',:id => retval["_id"], :advertisement => {title: "updated title1", linked: "www.google.com"} ,:format => :json
		
		advertisement = Advertisement.all.first
		assert_equal advertisement.linked, "www.google.com"
		assert_equal advertisement.user, user
		sign_out
		
		clear(User, Advertisement)
  end
  
  test "04 should post destroy with a admin user" do 
  	clear(User, Advertisement)
  	
  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		#create
		sign_in(user.email, Encryption.decrypt_password(user.password))
		post 'create', :advertisement => {title: "title1", linked: "www.baidu.com"} ,:format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval["title"], "title1"
		advertisement = Advertisement.where(title: "title1").first
		assert_equal advertisement.linked, "www.baidu.com"
		assert_equal advertisement.user, user
		
		#destroy
		post 'destroy', :id => retval["_id"], :format => :json
		retval = Faq.where(_id: retval["_id"]).first
		assert_equal retval, nil
		sign_out
		
		clear(User, Advertisement)
  end
  
end
