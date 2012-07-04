require 'test_helper'

class PresentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "present name should be" do
  	present = FactoryGirl.create(:present)
  	assert present.name == "Kindle", "Kindle"
  end

  test ""

end
