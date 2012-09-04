class TemplateQuestionAnswer
	include Mongoid::Document
	include Mongoid::Timestamps

	field :content, :type => Hash, :default => {"template_question_answer_content" => nil}

	belongs_to :user
	belongs_to :template_question

	def update_content(value)
		self.content["template_question_answer_content"] = value
		self.save
	end

	#--
	# Class methods
	#++

	def self.update_or_create(template_question_id, user_id, value)
		result = self.where(template_question_id: template_question_id, 
									user_id: user_id).to_a
		tqa = result[0] if result.count > 0

		if tqa then
			tqa.update_content(value)
		else
			self.create(template_question_id: template_question_id, 
					user_id: user_id,
					content: {"template_question_answer_content" => value})
		end
	end
end