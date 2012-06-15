require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ThirdPartyUserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  test "01 create tp user" do
    #create method return bool
    assert ThirdPartyUser.create(GoogleUser, "123456789", "21412413413431")
  end
  
  test "02 update method" do
    
    @@tp_user = ThirdPartyUser.find_by_website_and_user_id("google","123456789")
    @@tp_user = ThirdPartyUser.update_by_hash(@@tp_user, {:email => "test@test.com"})
    assert false if @@tp_user.nil?
    assert @@tp_user.email.to_s=="test@test.com" if @@tp_user
  end
  
  test "03 find method " do
    @@tp_user = ThirdPartyUser.find_by_website_and_user_id("google","123456789")
    assert !@@tp_user.nil?
    
    @@tp_user = ThirdPartyUser.find_by_webuserclass_and_user_id(GoogleUser,"123456789")
    assert !@@tp_user.nil?
    
    @@tp_user = ThirdPartyUser.find_by_webuserclass_and_email(GoogleUser,"test@test.com")
    assert !@@tp_user.nil?
  end
  
  test "04 successful? method" do 
    user  = ThirdPartyUser.new 
    assert user.successful?({"error" => 100034}) == false
    assert user.successful?({"error_id" => 23433}) == false
    assert user.successful?({"erro" => 2343}) == true
  end
end
