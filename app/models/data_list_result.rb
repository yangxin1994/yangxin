require 'error_enum'
require 'array'
require 'tool'
require 'digest/md5'
class DataListResult < Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :answer_info, :type => Array

	belongs_to :survey

	def get_answer_info
		ref_result_id.nil? ? answer_info : Result.find_by_result_id(result.ref_result_id).answer_info
	end

end
