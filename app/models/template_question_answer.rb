class TemplateQuestionAnswer
	include Mongoid::Document
	include Mongoid::Timestamps

	field :content, :type => Hash, :default => {}

	belongs_to :users
	belongs_to :template_questions
end
