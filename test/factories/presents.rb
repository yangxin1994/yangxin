# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :present do
  	name 'Kindle 4'
  	present_type 1
  	point 500
  	quantity 20
  	image_id 'image_id'
  	description 'amazon Kindle'
  	start_time Time.now
  	end_time Time.now.next_month
  	status 1
  end
  factory :present_old do
    name 'Kindle 2'
    present_type 1
    point 500
    quantity 20
    image_id 'image_id'
    description 'amazon Kindle 2'
    start_time Time.now
    end_time Time.now.next_month
    status 0
  end
end
