require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, choice questions also have:
# {
#	 "choices" : array of choice items(array),
#	 "choice_num_per_row" : number of choices items in one row(integer),
#	 "min_choice" : number of choices that user at least selects(integer),
#	 "max_choice" : number of choices that user at most selects(integer),
#	 "is_list_style" : whether show choices in list style(bool),
#	 "is_rand" : whether randomly show choices(bool),
#	}
#The element in the "choices" array has the following structure
# {
#  "choice_id": the id of this choice input
#  "content": the content of the choice(string),
#  "has_input": whether there is a input field(bool),
#  "is_exclusive": whether this choice item is exclusive(bool)
# }
class ChoiceQuestion < Question
	field :question_type, :type => String, default: "choice"
	field :choices, :type => Array, default: []
	field :choice_num_per_row, :type => Integer, default: -1
	field :min_choice, :type => Integer, default: 1
	field :max_choice, :type => Integer, default: 1
	field :is_list_style, :type => Boolean, default: true
	field :is_rand, :type => Boolean, default: false

	ATTR_NAME_ARY = Question::ATTR_NAME_ARY + %w[question_type choices choice_num_per_row min_choice max_choice list_style rand]
	CHOICE_ATTR_ARY = %w[choice_id content has_input is_exclusive]

	#*description*: serialize the current instance into a question object
	#
	#*params*:
	#
	#*retval*:
	#* the question object
	def serialize
		super(ATTR_NAME_ARY)
	end

	#*description*: update the current question instance, including generate id for new inputs
	#
	#*params*:
	#* the question object
	#
	#*retval*:
	def update_question(question_obj)
		question_obj["choices"].each do |choice_obj|
			choice_obj.delete_if { |k, v| !CHOICE_ATTR_ARY.include?(k) }
		end
		super(ATTR_NAME_ARY, question_obj)
		self.choices.each do |choice|
			choice["choice_id"] = SecureRandom.uuid if choice["choice_id"].to_s == ""
		end
		self.save
	end

	#*description*: clone the current question instance, including generate input ids for new instance
	#
	#*params*:
	#
	#*retval*:
	#* the cloned instance
	def clone
		new_inst = super
		new_inst.choices.each do |choice|
			choice["choice_id"] = SecureRandom.uuid
		end
		return new_inst
	end
end
