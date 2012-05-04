require 'error_enum'
require 'securerandom'
#Besides the fields that all types questions have, const sum questions also have:
# {
#	 "items" : array of items(array),
#	 "is_rand" : whether randomly show blanks(bool)
#	 "sum" : sum value(int)
#	}
#The element in the "item" array has the following structure
# {
#	 "item_id": id of the input
#  "content": content of the item(string),
#  "has_input": whether there is a input text field(bool)
# }
class ConstSumQuestion < Question
	field :question_type, :type => String, default: "const_sum"
	field :items, :type => Array, default: []
	field :is_rand, :type => Boolean, default: false
	field :sum, :type => Integer, default: 100

	ATTR_NAME_ARY = Question::ATTR_NAME_ARY + %w[question_type inputs rand sum]
	ITEM_ATTR_ARY = %w[item_id content has_input]

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
		question_obj["items"].each do |item_obj|
			item_obj.delete_if { |k, v| !ITEM_ATTR_ARY.include?(k) }
		end
		super(ATTR_NAME_ARY, question_obj)
		self.items.each do |item|
			item["item_id"] = SecureRandom.uuid if item["item_id"].to_s == ""
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
		new_inst.items.each do |item|
			item["item_id"] = SecureRandom.uuid
		end
		return new_inst
	end

end
