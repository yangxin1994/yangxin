FactoryGirl.define do
	factory :choice_question, class: Question do
		question_type QuestionTypeEnum::CHOICE_QUESTION
		issue ChoiceIssue.new.serialize
	end

	factory :text_blank_question, class: Question do
		question_type QuestionTypeEnum::TEXT_BLANK_QUESTION
		issue TextBlankIssue.new.serialize
	end

	factory :number_blank_question, class: Question do
		question_type QuestionTypeEnum::NUMBER_BLANK_QUESTION
		issue NumberBlankIssue.new.serialize
	end
end