FactoryGirl.define do
  factory :increase_point, class: PointLog do
  	operated_point 500
  	cause 1 #AdminOperate
    operated_admin factory: :admin_foo
    user factory: :user_bar
    
  end
end