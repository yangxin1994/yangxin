require 'test_helper'

class FaqsControllerTest < ActionController::TestCase
  
	test "00 init test db data. Everything action data format be JSON." do
		clear(User, Faq)
		@@normal_user = User.new(email: "test@example.com", password: Encryption.encrypt_password("123456"))
		@@normal_user.status = 2
		@@normal_user.role = 0
		@@normal_user.save
		@@admin_user = User.new(email:"test2@example.com", password: Encryption.encrypt_password("123456"))
		@@admin_user.status = 2
		@@admin_user.role = 1
		@@admin_user.save
	end
	
	test "99 clear test db data" do 
		clear(User,Faq)
	end 

	test "01 should get index action and no faq record" do
		get 'index', :format => :json
		assert_equal JSON.parse(@response.body), []		
	end
	
	test "02 should post create action which is without auth" do
		#sign_in(@@normal_user.email, Encryption.decrypt_password(@@normal_user.password))
		post 'create', :faq => {faq_type: "type1", question: "question1", answer: "answer1"}, :format => :json
		faq = JSON.parse(@response.body)
		assert_equal faq["question"], "question1"
		assert_equal faq["answer"], "answer1"
	end
	
	test "03 should get index action and has one faq record in 02 step" do
		faq = Faq.where(faq_type: "type1").first
		get 'index', :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval[0]["question"], "question1"
	end
	
	test "04 should post update action which is without auth" do 
		faq = Faq.where(faq_type: "type1").first
		if faq then
			assert_equal faq.question, "question1"
			post 'update', :id => faq.id.to_s, :faq => {question: "updated question1"}, :format => :json
			faq = Faq.where(faq_type: "type1").first
			assert_equal faq["question"], "updated question1"
			assert_equal faq["answer"], "answer1"
		end
	end
	
	test "05 should get condition action which is without auth" do
		get 'condition', :key => "type", :value => "type1", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval[0]["question"], "updated question1"

		get 'condition', :key => "question", :value => "question", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval[0]["question"], "updated question1"

		get 'condition', :key => "answer", :value => "answ", :format => :json
		retval = JSON.parse(@response.body)
		assert_equal retval[0]["question"], "updated question1"
	end
	
	test "06 should delete destroy action which is without auth" do
		faq = Faq.where(faq_type: "type1").first
		if faq then
			post 'destroy', :id => faq.id.to_s, :format => :json
			faq = Faq.where(faq_type: "type1").first
			assert_equal faq, nil
		end
	end
  
end
