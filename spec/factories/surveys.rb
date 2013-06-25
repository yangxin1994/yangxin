FactoryGirl.define do
	factory :survey do |s|
		s.sequence(:status) { |n| 2 ** ((n + 3) % 3) }
		s.sequence(:title) { |n| "title#{n}news" }
		s.quillme_promote true
		s.quillme_hot true
		s.spreadable true
	end

end