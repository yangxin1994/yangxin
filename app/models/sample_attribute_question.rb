require 'error_enum'
class SampleAttributeQuestion < BasicQuestion
	field :is_default, :type => Boolean, default: false
	# 1 for normal, 2 for deleted
	field :status, :type => Integer, default: 1
	field :relation, :type => Hash, default: {}

	belongs_to :sample_attribute

	scope :normal, where(status: 1)

	def self.create_sample_attribute_question(question_type, sample_attribute_id, relation)
		sample_attribute = SampleAttribute.find_by_id(sample_attribute_id)
		return ErrorEnum::SAMPLE_ATTRIBUTE_NOT_EXIST if sample_attribute.nil?

		sample_attribute_question = SampleAttribute
	end
end
