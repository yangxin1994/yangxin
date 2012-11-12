require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "should get point of currentuser" do
  	jesse = init_jesse
		auth_key = sign_in(jesse.email, Encryption.decrypt_password(jesse.password))
		get :point, :format => :json, :auth_key => auth_key
		result = JSON.parse(@response.body)
		assert result["value"] == 0
	end
end
