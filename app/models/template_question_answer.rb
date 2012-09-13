class TemplateQuestionAnswer
	include Mongoid::Document
	include Mongoid::Timestamps

	field :content, :type => Hash, :default => {"template_question_answer_content" => nil}

	belongs_to :user
	belongs_to :template_question

	def update_content(value)
		value.sort! if value.class == Array
		self.content["template_question_answer_content"] = value
		self.save
	end

	#--
	# Class methods
	#++

	def self.find_by_template_question_id_and_user_id(template_question_id, user_id)
		record = self.where(template_question_id: template_question_id, 
								user_id: user_id)[0]
		return record
	end

	def self.update_or_create(template_question_id, user_id, value)
		tqa = self.find_by_template_question_id_and_user_id(template_question_id, user_id)
		if tqa then
			tqa.update_content(value)
		else
			self.create(template_question_id: template_question_id, 
					user_id: user_id,
					content: {"template_question_answer_content" => value})
		end
	end

	def self.user_ids_satisfied(user_ids, c)
		q_id = c.name
		input_ids = c.value.sort!
		fuzzy = c.fuzzy
		
		t_question = TemplateQuestion.find_by_id(c.name)
		return [] if t_question.nil?
		user_ids_selected = []

		if !fuzzy
			user_ids_selected = 
				t_question.template_question_answers.where(content: {"template_question_answer_content" => input_ids.sort}).map { |e| e.user_id.to_s }
		else
			# template questions cannot have other item
			all_input_ids = t_question.issue["choices"].map { |e| e["input_id"] }
			other_input_ids = all_input_ids - input_ids
			possible_input_ids = []
			possible_number = 2 ^ other_input_ids.length
			0.upto(possible_number-1) do |x|
				binary_exp = x.to_s(2)
				cur_input_ids = []
				other_input_ids.each_with_index do |input_id, index|
					cur_input_ids << input_id if binary_exp[index] == "1"
				end
				cur_input_ids |= input_ids
				possible_input_ids << cur_input_ids
			end

			possible_input_ids.each do |input_ids|
				user_ids_selected |= 
					t_question.template_question_answers.where(content: {"template_question_answer_content" => input_ids.sort}).map { |e| e.user_id.to_s }
			end
		end
		return user_ids & user_ids_selected
	end

	def self.user_ids_unsatisfied(user_ids, c)
		q_id = c.name
		input_ids = c.value.sort!
		fuzzy = c.fuzzy
		
		t_question = TemplateQuestion.find_by_id(c.name)
		return [] if t_question.nil?
		user_ids_selected = []

		if !fuzzy
			user_ids_selected = 
				t_question.template_question_answers.where(content: {"template_question_answer_content" => input_ids.sort}).map { |e| e.user_id.to_s }
		else
			# template questions cannot have other item
			all_input_ids = t_question.issue["choices"].map { |e| e["input_id"] }
			other_input_ids = all_input_ids - input_ids
			possible_input_ids = []
			possible_number = 2 ^ other_input_ids.length
			0.upto(possible_number-1) do |x|
				binary_exp = x.to_s(2)
				cur_input_ids = []
				other_input_ids.each_with_index do |input_id, index|
					cur_input_ids << input_id if binary_exp[index] == "1"
				end
				cur_input_ids |= input_ids
				possible_input_ids << cur_input_ids
			end

			possible_input_ids.each do |input_ids|
				user_ids_selected |= 
					t_question.template_question_answers.where(content: {"template_question_answer_content" => input_ids.sort}).map { |e| e.user_id.to_s }
			end
		end
		answered_user_ids = t_question.template_question_answers.map { |e| e.user_id.to_s }
		return user_ids & (answered_user_ids - user_ids_selected)
	end
end