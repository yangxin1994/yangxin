require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, paragraph also have:
class Paragraph < Question
	field :question_type, :type => String, default: "paragraph"

	ATTR_NAME_ARY = Question::ATTR_NAME_ARY + %w[question_type]

	#*description*: serialize the current instance into a question object
	#
	#*params*:
	#
	#*retval*:
	#* the question object
	def serialize
		super(ATTR_NAME_ARY)
	end

	#*description*: update the current question instance
	#
	#*params*:
	#* the question object
	#
	#*retval*:
	def update_question(question_obj)
		super(ATTR_NAME_ARY, question_obj)
		self.save
	end

	#*description*: clone the current question instance
	#
	#*params*:
	#
	#*retval*:
	#* the cloned instance
	def clone
		new_inst = super
		return new_inst
	end
end
