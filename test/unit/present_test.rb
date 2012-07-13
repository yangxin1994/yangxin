require 'test_helper'

class PresentTest < ActiveSupport::TestCase
	# test "the truth" do
	#   assert true
	# end
	test "Present Creation" do
		present = FactoryGirl.create(:present)
		assert present.name == "Kindle 4", "has sth wrong"
	end

	# test "" do
	# 
	# end


	test "Present models clear" do
		clear(Present)
		assert_equal nil, Present.first
	end

	
end
