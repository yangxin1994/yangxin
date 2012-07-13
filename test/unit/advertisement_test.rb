require 'test_helper'

class AdvertisementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  test "01 test rewrite instance method: save" do 
	  	clear(User, Advertisement)
	  	
		# origin save method must be work which is without user 
		advertisement = Advertisement.new(title: "title1", linked: "www.baidu.com")
		assert advertisement.save
		assert_equal advertisement.user_id, nil
	  	
	  	# new save method must be work which is with user
	  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		advertisement = Advertisement.new(title: "title2", linked: "www.baidu.com")
		assert advertisement.save(user)
		assert_equal advertisement.user, user
	  	
	  	clear(User, Advertisement)
  end
  
  test "02 test rewrite instance method: update_attributes" do
		clear(User, Advertisement)
		
		advertisement = Advertisement.new(title: "title1", linked: "www.baidu.com")
		assert advertisement.save
		
		# origin update_attributes method must be work which is without user 
		assert advertisement.update_attributes({linked: "www.google.com"})
		assert_equal advertisement.linked, "www.google.com"
	  	
	  	# new update_attributes method must be work which is with user
	  	user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		user.status = 2
		user.role = 1
		user.save
		
		assert advertisement.update_attributes({linked: "www.google.com.hk"}, user)	
		assert_equal advertisement.user, user
		assert_equal advertisement.linked, "www.google.com.hk"
		
	  	clear(User, Advertisement)
  end

end
