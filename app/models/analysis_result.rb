require 'error_enum'
require 'array'
require 'tool'
require 'digest/md5'
class AnalysisResult < Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :duration_result, :type => Float
	field :time_result, :type => Hash
	field :region_result, :type => Hash
	field :channel_result, :type => Hash
	field :answers_result, :type => Hash

	belongs_to :survey

end
