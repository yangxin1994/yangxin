# encoding: utf-8
FactoryGirl.define do
	factory :public_notice do |s|
	  s.title " oli1312312386@gmail.com "
	  s.content "afdfsafsafsafsafsafsfasfsf"
	  s.status 2
	  s.user_id "51139228408c997fc10000e6"
	end

	factory :public_notice_deleted, parent: :public_notice do
		title "86@gmail.com"
		content ""
		status 4
		user_id ""
	end
end